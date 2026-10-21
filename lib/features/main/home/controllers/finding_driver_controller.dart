import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/data/repositories/enquiry_api/enquiry_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/utils/map_pin.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import 'package:url_launcher/url_launcher.dart';

enum FindingDriverSource { booking, ongoing }

class FindingDriverController extends GetxController {
  final TripStateService _tripStateService = Get.find<TripStateService>();

  RxSet<Marker> get markers => _tripStateService.markers;
  RxSet<Polyline> get polylines => _tripStateService.polylines;

  String get endOtp => _tripStateService.selectedTrip?.endOtp ?? '----';

  RxSet<Marker> get nearbyDriverMarkers => Get.find<HomeController>().driverMarkers;
  Timer? _nearbyPollTimer;
  int _nearbyPollTicks = 0;

  final EnquiryRepository _enquiryRepo = EnquiryRepository();
  final driverDistance = ''.obs;
  final driverEta = ''.obs;
  final RxnDouble roadDistanceKm = RxnDouble();

  double _routeKm(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double meters = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      meters += Geolocator.distanceBetween(
        pts[i].latitude,
        pts[i].longitude,
        pts[i + 1].latitude,
        pts[i + 1].longitude,
      );
    }
    return meters / 1000;
  }

  final searchTimedOut = false.obs;
  int _dispatchSeconds = 0;

  int get dispatchTotalSeconds => _dispatchSeconds > 0 ? _dispatchSeconds : 90;
  int get nearbyDriverCount => nearbyDriverMarkers.length;

  GoogleMapController? mapController;

  final Rx<LatLng?> deviceLocation = Rx<LatLng?>(null);
  StreamSubscription<Position>? _devicePosSub;

  final Rx<BitmapDescriptor?> destinationIcon = Rx<BitmapDescriptor?>(null);
  final Rx<BitmapDescriptor?> currentLocationIcon = Rx<BitmapDescriptor?>(null);
  RxDouble apiProgress = 0.0.obs;
  RxBool isDriverFound = false.obs;
  RxMap<String, dynamic> driverDetails = <String, dynamic>{}.obs;
  bool _isSearching = false;
  bool _wasInProgress = false;
  int _lastSeenLeg = 1;

  final showStops = false.obs;
  final showCancelAction = false.obs;

  VehicleSelectionController get vehicleSelectionController => Get.find<VehicleSelectionController>();
  final pickup = ''.obs;
  final dropoff = ''.obs;
  final distance = 0.0.obs;
  final duration = 0.obs;
  final price = ''.obs;
  final vehicleType = ''.obs;

  final source = FindingDriverSource.booking.obs;

  @override
  void onInit() async {
    super.onInit();

    final args = Get.arguments ?? {};

    pickup.value = args['pickup'] ?? '';
    dropoff.value = args['dropoff'] ?? '';
    distance.value = args['distance'] ?? 0.0;
    duration.value = args['duration'] ?? 0;
    price.value = args['price'] ?? '';
    vehicleType.value = args['vehicleType'] ?? '';
    source.value = _parseSource(args['source'] ?? _tripStateService.entrySource.value);

    _loadDispatchConfig();

    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/destination_marker.png',
    ).then((d) => destinationIcon.value = d);

    _loadCarTopIcon().then((d) => currentLocationIcon.value = d);

    _loadMapData();

    ever(_tripStateService.activeTrips, (_) => _updateDriverState(_tripStateService.selectedTrip));
    ever(_tripStateService.selectedBookingId, (_) => _updateDriverState(_tripStateService.selectedTrip));

    _updateDriverState(_tripStateService.selectedTrip);

    if (!isDriverFound.value && _isDispatchSearching) _startNearbyPolling();

    ever(_tripStateService.driverLocation, (LatLng? loc) {
      if (loc == null) return;
      _updateDriverRoute(loc);
      _seedApproxDistance(loc);
      if (_isInProgress) {
        _refreshInProgressRouteThrottled();
      } else {
        _focusDriver(loc);
      }
    });

    ever(deviceLocation, (LatLng? loc) {
      if (loc == null || !_isInProgress) return;
      _refreshInProgressRouteThrottled();
    });

    ever(_tripStateService.activeStages, (_) {
      if (_isInProgress && !_wasInProgress) {
        _wasInProgress = true;
        drawInProgressRoute();
      } else if (!_isInProgress) {
        _wasInProgress = false;
      }
    });

    ever(_tripStateService.activeTrips, (_) {
      final int leg = _tripStateService.selectedLeg;
      if (leg == _lastSeenLeg) return;
      _lastSeenLeg = leg;
      if (!_isInProgress) return;
      _prewarmedRoute = null;
      resetInProgressRoute();
      drawInProgressRoute();
    });

    void applyTrackDistance(double? km) {
      if (km == null) return;
      driverDistance.value = '${km.toStringAsFixed(1)} km away';
    }

    void applyTrackDuration(int? min) {
      if (min == null) return;
      driverEta.value = min < 1 ? '< 1 min' : '$min min';
      driverDetails['arrivalTime'] = driverEta.value;
    }

    ever(_tripStateService.trackDistanceKm, applyTrackDistance);
    ever(_tripStateService.trackDurationMin, applyTrackDuration);
    applyTrackDistance(_tripStateService.trackDistanceKm.value);
    applyTrackDuration(_tripStateService.trackDurationMin.value);

    ever(_tripStateService.noDriversBookingId, (String? bookingId) {
      if (bookingId == null || bookingId.isEmpty) return;
      final selected = _tripStateService.selectedBookingId.value;
      if (selected.isNotEmpty && bookingId != selected) return;
      _tripStateService.noDriversBookingId.value = null;
      if (isDriverFound.value) return;
      _onSearchTimeout();
    });

    final initialLoc = _tripStateService.driverLocation.value;
    if (initialLoc != null) _updateDriverRoute(initialLoc);

    if (_isInProgress) {
      _wasInProgress = true;
      drawInProgressRoute();
    }
  }

  LatLng _tripPickup() {
    final t = _tripStateService.selectedTrip;
    if (t?.pickupLat != null && t?.pickupLng != null) {
      return LatLng(t!.pickupLat!, t.pickupLng!);
    }
    return Get.find<HomeController>().pickupLatLng.value;
  }

  LatLng _tripDestination() {
    final active = _tripStateService.activeDestinationFor(null);
    if (active != null) return active;

    final t = _tripStateService.selectedTrip;
    if (t?.dropLat != null && t?.dropLng != null) {
      return LatLng(t!.dropLat!, t.dropLng!);
    }
    return Get.find<HomeController>().destinationLatLng.value;
  }

  bool get _isInProgress => _tripStateService.selectedStage == RideStage.tripInProgress;
  LatLng _routeTarget() => _isInProgress ? _tripDestination() : _tripPickup();

  List<LatLng> _tripStops() {
    if (_tripStateService.selectedLeg >= 2) return const [];
    final raw = _tripStateService.selectedTrip?.stops ?? _tripStateService.lastBookingStops;
    final points = <LatLng>[];
    for (final stop in raw) {
      final lat = double.tryParse((stop['lat'] ?? stop['latitude'])?.toString() ?? '');
      final lng = double.tryParse((stop['lng'] ?? stop['longitude'])?.toString() ?? '');
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  Future<void> _syncStopMarkers(List<LatLng> stops) async {
    markers.removeWhere((m) => m.markerId.value.startsWith('stop_'));
    for (int i = 0; i < stops.length; i++) {
      final icon = await MapPin.build(color: AppColors.orangeAccent, label: '${i + 1}', size: 42);
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: stops[i],
          icon: icon,
          anchor: MapPin.anchor,
          zIndexInt: 2,
          infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
        ),
      );
    }
    markers.refresh();
  }

  Future<void> _updateDriverRoute(LatLng driver) async {
    if (!isDriverFound.value) return;
    if (_isInProgress) return;
    try {
      final home = Get.find<HomeController>();
      final coords = await home.getRouteCoords(driver, _routeTarget());
      if (coords.isEmpty) return;
      if (_isInProgress) roadDistanceKm.value = _routeKm(coords);
      polylines.assignAll({
        Polyline(
          polylineId: const PolylineId('route_casing'),
          points: coords,
          color: AppColors.info.withAlpha(10),
          width: 9,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 0,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: coords,
          color: AppColors.info,
          width: 2,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 1,
        ),
      });
      polylines.refresh();
    } catch (_) {}
  }

  DateTime? _lastRouteRefreshAt;
  LatLng? _lastRouteOrigin;
  static const Duration _routeRefreshInterval = Duration(seconds: 10);
  static const Duration _routeMaxAge = Duration(minutes: 2);
  static const double _routeMoveThresholdMetres = 150;

  void _refreshInProgressRouteThrottled() {
    if (_tripStateService.isSelectedHalted) return;
    final now = DateTime.now();
    final DateTime? last = _lastRouteRefreshAt;
    if (last != null) {
      if (now.difference(last) < _routeRefreshInterval) return;

      final LatLng? origin = deviceLocation.value ?? _tripStateService.driverLocation.value;
      final LatLng? anchor = _lastRouteOrigin;
      final bool stale = now.difference(last) >= _routeMaxAge;
      final bool moved =
          origin == null ||
          anchor == null ||
          Geolocator.distanceBetween(anchor.latitude, anchor.longitude, origin.latitude, origin.longitude) >=
              _routeMoveThresholdMetres;
      if (!stale && !moved) return;
    }
    drawInProgressRoute();
  }

  void _paintRoute(List<LatLng> pts) {
    polylines.assignAll({
      Polyline(
        polylineId: const PolylineId('route_casing'),
        points: pts,
        color: AppColors.info.withAlpha(10),
        width: 9,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 0,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: pts,
        color: AppColors.info,
        width: 2,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 1,
      ),
    });
    polylines.refresh();
  }

  bool _startsNear(List<LatLng> pts, LatLng origin, {double metres = 1500}) {
    if (pts.isEmpty) return false;
    return Geolocator.distanceBetween(pts.first.latitude, pts.first.longitude, origin.latitude, origin.longitude) <
        metres;
  }

  List<LatLng> _anchorToOrigin(List<LatLng> pts, LatLng origin) {
    if (pts.isEmpty) return pts;

    int nearest = 0;
    double best = double.infinity;
    for (int i = 0; i < pts.length; i++) {
      final double d = Geolocator.distanceBetween(pts[i].latitude, pts[i].longitude, origin.latitude, origin.longitude);
      if (d < best) {
        best = d;
        nearest = i;
      }
    }

    final List<LatLng> trimmed = nearest == 0 ? pts : pts.sublist(nearest);
    return best < 30 ? trimmed : [origin, ...trimmed];
  }

  List<LatLng>? get _prewarmedRoute {
    if (_tripStateService.prewarmedRouteKey != _tripStateService.routeCacheKey(null)) return null;
    return _tripStateService.prewarmedRoute;
  }

  set _prewarmedRoute(List<LatLng>? coords) {
    final double? km = (coords == null || coords.isEmpty) ? null : _routeKm(coords);
    _tripStateService.cachePrewarmedRoute(coords, km: km, min: km == null ? null : (km / 25 * 60).round());
  }

  void _paintCachedRoute(LatLng? origin) {
    final cached = _prewarmedRoute;
    if (cached == null || cached.isEmpty) return;
    if (origin != null && !_startsNear(cached, origin)) {
      _prewarmedRoute = null;
      return;
    }
    roadDistanceKm.value = _tripStateService.prewarmedRouteKm ?? _routeKm(cached);
    final int? cachedMin = _tripStateService.prewarmedRouteMin;
    if (driverEta.value.isEmpty && cachedMin != null) {
      driverEta.value = cachedMin < 1 ? '< 1 min' : '$cachedMin min';
      driverDetails['arrivalTime'] = driverEta.value;
    }
    _paintRoute(origin == null ? cached : _anchorToOrigin(cached, origin));
    _inProgressRoutePainted = true;
  }

  bool _prewarming = false;

  Future<void> prewarmTripRoute() async {
    if (_prewarming || _prewarmedRoute != null) return;

    final trip = _tripStateService.selectedTrip;
    final lat = trip?.pickupLat;
    final lng = trip?.pickupLng;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return;

    _prewarming = true;
    try {
      final coords = await Get.find<HomeController>().getRouteCoords(
        LatLng(lat, lng),
        _tripDestination(),
        waypoints: _tripStops(),
      );
      if (coords.isNotEmpty) _prewarmedRoute = coords;
    } catch (_) {
    } finally {
      _prewarming = false;
    }
  }

  Future<void>? _drawFuture;
  DateTime? _drawStartedAt;
  Timer? _routeRetryTimer;
  int _routeFailStreak = 0;
  bool _inProgressRoutePainted = false;
  bool _routeInputsDirty = false;

  static const List<int> _routeRetryDelays = [2, 5, 10];

  Future<void> drawInProgressRoute() {
    final existing = _drawFuture;
    final startedAt = _drawStartedAt;
    final bool stale = startedAt != null && DateTime.now().difference(startedAt) > const Duration(seconds: 15);
    if (existing != null && !stale) {
      if (!_routeInputsDirty) return existing;
      _routeInputsDirty = false;
      return existing.then((_) => drawInProgressRoute());
    }

    _routeRetryTimer?.cancel();
    _drawStartedAt = DateTime.now();
    late final Future<void> future;
    future = _runDrawInProgressRoute().whenComplete(() {
      if (identical(_drawFuture, future)) {
        _drawFuture = null;
        _drawStartedAt = null;
      }
    });
    _drawFuture = future;
    return future;
  }

  void _seedApproxDistance(LatLng driver) {
    if (!_isInProgress || roadDistanceKm.value != null) return;
    final dest = _tripStateService.activeDestinationFor(null);
    if (dest == null) return;
    final LatLng from = deviceLocation.value ?? driver;
    final double meters = Geolocator.distanceBetween(from.latitude, from.longitude, dest.latitude, dest.longitude);
    if (meters > 0) roadDistanceKm.value = meters / 1000;
  }

  void _scheduleRouteRetry(String reason) {
    final int index = _routeFailStreak < _routeRetryDelays.length ? _routeFailStreak : _routeRetryDelays.length - 1;
    final int seconds = _routeRetryDelays[index];
    if (_routeFailStreak < _routeRetryDelays.length) _routeFailStreak++;
    _routeRetryTimer?.cancel();
    _routeRetryTimer = Timer(Duration(seconds: seconds), () {
      if (_isInProgress) drawInProgressRoute();
    });
  }

  Future<void> _runDrawInProgressRoute() async {
    if (!Get.isRegistered<HomeController>()) return;

    if (!_inProgressRoutePainted) {
      _paintCachedRoute(deviceLocation.value ?? _tripStateService.driverLocation.value);
    }

    if (_tripStateService.activeDestinationFor(null) == null) {
      _scheduleRouteRetry('destination not resolved');
      return;
    }

    final home = Get.find<HomeController>();

    if (deviceLocation.value == null) await _refreshDeviceLocationOnce();
    final LatLng? origin = deviceLocation.value;
    if (origin == null) {
      _scheduleRouteRetry('device location unavailable');
      return;
    }

    final LatLng destination = _tripDestination();

    try {
      if (!_inProgressRoutePainted) _paintCachedRoute(origin);

      final stops = _tripStops();
      await _syncStopMarkers(stops);
      var coords = await home.getRouteCoords(origin, destination, waypoints: stops);

      if (coords.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
        coords = await home.getRouteCoords(origin, destination, waypoints: stops);
      }
      if (coords.isEmpty) {
        _scheduleRouteRetry(home.lastRouteError ?? 'empty route');
        return;
      }

      final double km = _routeKm(coords);
      if (km <= 0) {
        _scheduleRouteRetry('zero length route');
        return;
      }

      roadDistanceKm.value = km;
      _paintRoute(_anchorToOrigin(coords, origin));
      _inProgressRoutePainted = true;
      _prewarmedRoute = coords;
      _routeFailStreak = 0;
      _lastRouteRefreshAt = DateTime.now();
      _lastRouteOrigin = origin;
    } catch (e) {
      _scheduleRouteRetry('exception: $e');
    }
  }

  void resetInProgressRoute() {
    _syncStopMarkers(_tripStops());
    _inProgressRoutePainted = false;
    _lastRouteRefreshAt = null;
    _lastRouteOrigin = null;
    _routeFailStreak = 0;
    _routeRetryTimer?.cancel();
    if (_drawFuture != null) _routeInputsDirty = true;
  }

  void _focusDriver(LatLng driver) => _zoomToFitDriverPickup(driver);

  Future<void> _zoomToFitDriverPickup(LatLng driver, {bool retry = true}) async {
    final controller = mapController;
    if (controller == null) return;

    final pickup = _routeTarget();

    double swLat = driver.latitude < pickup.latitude ? driver.latitude : pickup.latitude;
    double neLat = driver.latitude > pickup.latitude ? driver.latitude : pickup.latitude;
    double swLng = driver.longitude < pickup.longitude ? driver.longitude : pickup.longitude;
    double neLng = driver.longitude > pickup.longitude ? driver.longitude : pickup.longitude;

    const double minSpan = 0.01;
    final double latMid = (swLat + neLat) / 2;
    final double lngMid = (swLng + neLng) / 2;
    if (neLat - swLat < minSpan) {
      swLat = latMid - minSpan / 2;
      neLat = latMid + minSpan / 2;
    }
    if (neLng - swLng < minSpan) {
      swLng = lngMid - minSpan / 2;
      neLng = lngMid + minSpan / 2;
    }

    final bounds = LatLngBounds(southwest: LatLng(swLat, swLng), northeast: LatLng(neLat, neLng));

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 90));
    } catch (_) {
      if (retry) {
        await Future.delayed(const Duration(milliseconds: 350));
        await _zoomToFitDriverPickup(driver, retry: false);
      }
    }
  }

  FindingDriverSource _parseSource(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    if (value == 'ongoing' || value == 'activetrips' || value == 'active_trips') {
      return FindingDriverSource.ongoing;
    }
    return FindingDriverSource.booking;
  }

  void handleBack() {
    switch (source.value) {
      case FindingDriverSource.ongoing:
        Get.back();
        break;

      case FindingDriverSource.booking:
        Get.offAllNamed(AppRoutes.home);
        if (Get.isRegistered<HomeController>()) Get.find<HomeController>().reconcileActiveTrips();
        break;
    }
  }

  void _updateDriverState(TripDetailsModel? activeTrip) {
    if (activeTrip != null &&
        activeTrip.driverName != null &&
        activeTrip.driverName!.isNotEmpty &&
        activeTrip.driverName != '0') {
      if (!isDriverFound.value) showCancelAction.value = false;
      isDriverFound.value = true;
      _isSearching = false;
      apiProgress.value = 1.0;
      searchTimedOut.value = false;
      _stopNearbyPolling();
      if (driverEta.value.isEmpty) driverEta.value = activeTrip.arrivalTime ?? 'Calculating…';
      driverDetails.value = {
        'name': activeTrip.driverName,
        'rating': activeTrip.driverRating != null ? double.parse(activeTrip.driverRating!.toStringAsFixed(1)) : 0.0,
        'trips': activeTrip.driverTrips ?? '0',
        'arrivalTime': driverEta.value.isNotEmpty ? driverEta.value : (activeTrip.arrivalTime ?? 'Calculating…'),
        'vehicleName': activeTrip.vehicleModel ?? 'No vehicle',
        'vehicleType': activeTrip.vehicleType ?? 'Premium',
        'plateNumber': activeTrip.plateNumber ?? '-1',
        'pinCode': activeTrip.startOtp ?? '0000',
        'paymentMethod': activeTrip.paymentMethod ?? 'Cash',
        'fare': (activeTrip.customerFinalAmount ?? activeTrip.totalFare) != null
            ? '₹${(activeTrip.customerFinalAmount ?? activeTrip.totalFare)!.toStringAsFixed(2)}'
            : '₹0',
        'address': activeTrip.destinationLocation ?? '',
        'image': activeTrip.driverImage ?? '',
        'phone': activeTrip.driverPhone ?? '',
      };
      final loc = _tripStateService.driverLocation.value;
      if (loc != null) {
        _updateDriverRoute(loc);
        if (!_isInProgress) _focusDriver(loc);
      }
    } else {
      final bool wasFound = isDriverFound.value;
      isDriverFound.value = false;
      driverEta.value = '';
      if (wasFound) {
        _tripStateService.dispatchStartAt = DateTime.now();
        apiProgress.value = 0.0;
        searchTimedOut.value = false;
        _isSearching = false;
      }
      if (!_isDispatchSearching) {
        _isSearching = false;
        _stopNearbyPolling();
        return;
      }
      _startNearbyPolling();
      if (!_isSearching) {
        _startFindingProgress();
      }
    }
  }

  bool get _isDispatchSearching {
    final trip = _tripStateService.selectedTrip;
    if (trip == null) return false;
    final String status = (trip.status ?? '').toLowerCase();
    if (status == 'cancelled' || status == 'completed') return false;
    final RideStage stage = _tripStateService.selectedStage;
    return stage == RideStage.findingDriver || stage == RideStage.none;
  }

  int get _maxNearbyPollTicks => (dispatchTotalSeconds ~/ 30) + 2;

  void _startNearbyPolling() {
    if (_nearbyPollTimer != null) return;
    final home = Get.find<HomeController>();
    _nearbyPollTicks = 0;
    home.fetchNearbyDrivers();
    _nearbyPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _nearbyPollTicks++;
      if (isDriverFound.value || !_isDispatchSearching || _nearbyPollTicks > _maxNearbyPollTicks) {
        _stopNearbyPolling();
        return;
      }
      home.fetchNearbyDrivers();
    });
  }

  void _stopNearbyPolling() {
    _nearbyPollTimer?.cancel();
    _nearbyPollTimer = null;
  }

  @override
  void onClose() {
    _isSearching = false;
    _stopNearbyPolling();
    _routeRetryTimer?.cancel();
    _routeRetryTimer = null;
    _devicePosSub?.cancel();
    _devicePosSub = null;
    mapController = null;
    super.onClose();
  }

  void _onSearchTimeout() {
    if (isDriverFound.value) return;
    _isSearching = false;
    _stopNearbyPolling();
    searchTimedOut.value = true;
  }

  void retrySearch() {
    if (isDriverFound.value) return;
    searchTimedOut.value = false;
    _isSearching = false;
    _tripStateService.dispatchStartAt = DateTime.now();
    _startNearbyPolling();
    _startFindingProgress();
  }

  Future<void> changeRideType() async {
    final bookingId = _tripStateService.selectedTrip?.bookingId;
    _isSearching = false;
    _stopNearbyPolling();
    if (bookingId != null && bookingId.isNotEmpty) {
      try {
        await _enquiryRepo.cancelTrip(tripId: bookingId, reason: 'Changing ride type');
      } catch (_) {}
    }
    _tripStateService.clearTripDetails();
    await Get.offAllNamed(AppRoutes.home);
  }

  Future<void> notifyWhenAvailable() async {
    _isSearching = false;
    _stopNearbyPolling();
    AppSnackbar.success('We\'ll notify you', 'We\'ll alert you as soon as a driver accepts.');
    await Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _loadDispatchConfig() async {
    final secs = _tripStateService.dispatchSeconds;
    if (secs > 0) _dispatchSeconds = secs;

    final configVal = await AuthRepository().getConfigValue('totalDispatchSeconds');
    final parsed = int.tryParse(configVal ?? '');
    if (parsed != null && parsed > 0) _dispatchSeconds = parsed;
  }

  void _startFindingProgress() async {
    _isSearching = true;
    final DateTime? anchor = _tripStateService.dispatchStartAt;
    final int window = _dispatchSeconds > 0 ? _dispatchSeconds : 90;
    if (anchor == null || DateTime.now().difference(anchor).inSeconds >= window) {
      _tripStateService.dispatchStartAt = DateTime.now();
    }
    while (_isSearching && !isDriverFound.value) {
      final int total = _dispatchSeconds > 0 ? _dispatchSeconds : 90;
      final double elapsed = DateTime.now().difference(_tripStateService.dispatchStartAt!).inMilliseconds / 1000.0;
      apiProgress.value = (elapsed / total).clamp(0.0, 1.0);
      if (apiProgress.value >= 1.0) {
        _onSearchTimeout();
        break;
      }

      await Future.delayed(const Duration(seconds: 1));
      if (!_isSearching) return;
    }
  }

  void _loadMapData() {
    try {
      final homeController = Get.find<HomeController>();
      if (markers.isEmpty) {
        markers.addAll(homeController.markers);
      }
      if (polylines.isEmpty) {
        polylines.addAll(homeController.polylines);
      }
    } catch (_) {}
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (_isInProgress) {
      drawInProgressRoute();
      return;
    }

    if (isDriverFound.value) {
      final loc = _tripStateService.driverLocation.value;
      if (loc != null) {
        _updateDriverRoute(loc);
        _zoomToFitDriverPickup(loc);
      } else {
        _zoomToFitRoute();
      }
    } else {
      centerOnUser();
    }
  }

  void _zoomToFitRoute({bool retry = true}) {
    final ctrl = mapController;
    if (ctrl == null) return;

    final pts = <LatLng>[];
    for (final p in polylines) {
      pts.addAll(p.points);
    }
    for (final m in markers) {
      if (m.markerId.value == 'pickup') continue;
      pts.add(m.position);
    }

    if (pts.isEmpty) {
      if (retry) Future.delayed(const Duration(milliseconds: 400), () => _zoomToFitRoute(retry: false));
      return;
    }

    try {
      final bounds = Get.find<HomeController>().getBounds(pts);
      ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 90));
    } catch (_) {
      if (retry) Future.delayed(const Duration(milliseconds: 400), () => _zoomToFitRoute(retry: false));
    }
  }

  void zoomIn() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void restartDeviceLocationUpdates() {
    _devicePosSub?.cancel();
    _devicePosSub = null;
    ensureDeviceLocationUpdates();
  }

  bool _resuming = false;

  Future<void> refreshAfterResume() async {
    if (_resuming) return;
    _resuming = true;
    try {
      // final cached = _prewarmedRoute;

      restartDeviceLocationUpdates();
      await _refreshDeviceLocationOnce();
      await _refreshTripState();

      if (_isInProgress) {
        resetInProgressRoute();
        await drawInProgressRoute();
      } else {
        await _refreshPreTripRoute();
      }
      _seedTrackingFallback();
    } finally {
      _resuming = false;
    }
  }

  Future<void> _refreshPreTripRoute() async {
    final loc = _tripStateService.driverLocation.value;
    if (loc == null) {
      return;
    }
    await _updateDriverRoute(loc);
  }

  void refitPreTripCamera() {
    final loc = _tripStateService.driverLocation.value;
    if (loc == null) return;
    _zoomToFitDriverPickup(loc);
  }

  void _seedTrackingFallback() {
    if (_tripStateService.hasFreshTracking) return;
    final driver = _tripStateService.driverLocation.value;
    if (driver == null) return;

    final LatLng? target = _isInProgress ? _tripStateService.activeDestinationFor(null) : _tripPickup();
    if (target == null) return;

    final double km =
        Geolocator.distanceBetween(driver.latitude, driver.longitude, target.latitude, target.longitude) / 1000;
    if (km <= 0) return;

    final int mins = (km / 25 * 60).round();
    driverDistance.value = '${km.toStringAsFixed(1)} km away';
    driverEta.value = mins < 1 ? '< 1 min' : '$mins min';
    driverDetails['arrivalTime'] = driverEta.value;
    roadDistanceKm.value ??= km;
  }

  Future<void> _refreshDeviceLocationOnce() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      deviceLocation.value = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  Future<void> _refreshTripState() async {
    try {
      await _tripStateService.handleAppResumed();
    } catch (_) {}
  }

  void ensureDeviceLocationUpdates() {
    if (_devicePosSub != null) return;
    final seed = Get.find<HomeController>().currentLocation.value;
    if (seed.latitude != 11.0168 || seed.longitude != 76.9558) {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        deviceLocation.value = seed;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => deviceLocation.value = seed);
      }
    }
    _devicePosSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20),
        ).listen(
          (pos) {
            deviceLocation.value = LatLng(pos.latitude, pos.longitude);
          },
          onError: (e) {
            _devicePosSub?.cancel();
            _devicePosSub = null;
          },
          cancelOnError: true,
        );
  }

  Future<void> centerOnUser() async {
    try {
      final homeController = Get.find<HomeController>();
      final location = homeController.currentLocation.value;
      await mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: 15)));
    } catch (_) {}
  }

  Future<BitmapDescriptor> _loadCarTopIcon() async {
    try {
      final asset = await rootBundle.load('assets/icons/cartop.png');
      final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List(), targetWidth: (48 * dpr).round());
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.bytes(data!.buffer.asUint8List(), imagePixelRatio: dpr);
    } catch (_) {
      return BitmapDescriptor.asset(const ImageConfiguration(size: Size(48, 48)), 'assets/icons/driver_icon.png');
    }
  }

  Future<void> openDialer() async {
    final phone = driverDetails['phone']?.toString() ?? '';
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
