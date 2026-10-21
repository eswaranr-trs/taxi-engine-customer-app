import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:orange_taxi_customer_app/data/models/airport_model.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/location_service/location_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';
import 'package:orange_taxi_customer_app/features/main/chat/services/chat_unread_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/controllers/my_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';

import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';

import '../../../../config/routes/app_route.dart' show AppRoutes;
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final isInitialLoading = true.obs;

  bool canOpenSheet = true;
  GoogleMapController? googleMapController;

  GoogleMapController? homeMapController;

  var currentTab = 0.obs;
  DateTime? _lastBackPressAt;

  bool shouldExitOnBack() {
    final now = DateTime.now();
    if (_lastBackPressAt == null || now.difference(_lastBackPressAt!) > const Duration(seconds: 2)) {
      _lastBackPressAt = now;
      Fluttertoast.showToast(
        msg: 'Press back again to exit',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
    return true;
  }

  var isSelectingPickup = true.obs;
  var pickupAddress = 'Locating...'.obs;
  var destinationAddress = 'Where to?'.obs;
  var stops = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> get formattedStops => stops
      .map((stop) => {"address": stop['mainText'] ?? '', "lat": stop['lat'] ?? 0.0, "lng": stop['lng'] ?? 0.0})
      .toList();

  void moveStop(int from, int to) {
    if (to < 0 || to >= stops.length) return;
    final List<Map<String, dynamic>> reordered = [...stops];
    reordered.insert(to, reordered.removeAt(from));
    stops.assignAll(reordered);
  }

  var pickupLatLng = const LatLng(11.0168, 76.9558).obs;
  var destinationLatLng = const LatLng(11.0168, 76.9558).obs;

  static const double _currentLocationTolerance = 0.0005;

  bool _nearCurrent(LatLng p) =>
      (p.latitude - currentLocation.value.latitude).abs() < _currentLocationTolerance &&
      (p.longitude - currentLocation.value.longitude).abs() < _currentLocationTolerance;

  bool get isPickupCurrent => pickupAddress.value != 'Locating...' && _nearCurrent(pickupLatLng.value);

  bool get isDestinationCurrent => destinationAddress.value != 'Where to?' && _nearCurrent(destinationLatLng.value);

  static const double _duplicateTolerance = 0.0002;

  bool _samePlace(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < _duplicateTolerance && (a.longitude - b.longitude).abs() < _duplicateTolerance;

  String? conflictingSlotFor(LatLng target, {bool skipPickup = false, bool skipDestination = false, int? skipStop}) {
    if (!skipPickup && pickupAddress.value != 'Locating...' && _samePlace(target, pickupLatLng.value)) {
      return 'pickup';
    }
    if (!skipDestination && destinationAddress.value != 'Where to?' && _samePlace(target, destinationLatLng.value)) {
      return 'destination';
    }
    for (int i = 0; i < stops.length; i++) {
      if (i == skipStop) continue;
      final double? lat = (stops[i]['lat'] as num?)?.toDouble();
      final double? lng = (stops[i]['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      if (_samePlace(target, LatLng(lat, lng))) return 'stop ${i + 1}';
    }
    return null;
  }

  bool rejectIfDuplicate(LatLng target, {bool skipPickup = false, bool skipDestination = false, int? skipStop}) {
    final String? slot = conflictingSlotFor(
      target,
      skipPickup: skipPickup,
      skipDestination: skipDestination,
      skipStop: skipStop,
    );
    if (slot == null) return false;
    AppSnackbar.warning('Same location', 'This place is already set as your $slot. Choose a different one.');
    return true;
  }

  var currentLocation = const LatLng(11.0168, 76.9558).obs;

  var isToAirport = true.obs;
  Rx<AirportModel?> selectedAirport = Rx<AirportModel?>(null);
  Rx<TerminalModel?> selectedTerminal = Rx<TerminalModel?>(null);

  final List<AirportModel> mockAirports = [];

  var markers = <Marker>{}.obs;
  var driverMarkers = <Marker>{}.obs;
  BitmapDescriptor? onlineDriverIcon;
  BitmapDescriptor? onrideDriverIcon;
  BitmapDescriptor? offlineDriverIcon;
  var isMapSelectionMode = false.obs;
  var polylines = <Polyline>{}.obs;
  var distance = ''.obs;
  var duration = ''.obs;

  bool shouldReverseGeocode = true;
  bool isAnimating = false;
  var recentSearches = <Map<String, dynamic>>[].obs;
  var savedAddresses = <String, Map<String, dynamic>>{}.obs;

  String? editingSavedAddressType;

  final pickupFocusNode = FocusNode();
  final destinationFocusNode = FocusNode();

  StreamSubscription? connectivitySubscription;
  StreamSubscription<ServiceStatus>? locationSubscription;

  var hasInternet = true.obs;
  var isLocationServiceEnabled = true.obs;
  var hasLocationPermission = true.obs;

  final showCoachMarks = false.obs;

  Worker? _coachTripDataWorker;

  Future<void> maybeShowHomeCoachMarks() async {
    if (!await LocalStorageService.isSignupUser()) return;
    if (await LocalStorageService.hasSeenCoachMark('home_coach')) return;
    if (!Get.isRegistered<TripController>()) return;
    final tripController = Get.find<TripController>();
    if (tripController.tripData.isNotEmpty) {
      showCoachMarks.value = true;
      return;
    }

    _coachTripDataWorker?.dispose();
    _coachTripDataWorker = ever(tripController.tripData, (Map<TripType, Map<String, dynamic>> data) {
      if (data.isEmpty) return;
      _coachTripDataWorker?.dispose();
      _coachTripDataWorker = null;
      showCoachMarks.value = true;
    });
  }

  Future<void> finishHomeCoachMarks() async {
    showCoachMarks.value = false;
    await LocalStorageService.setSeenCoachMark('home_coach');
  }

  void reconcileActiveTrips() {
    if (Get.isRegistered<ActiveTripsController>()) {
      Get.find<ActiveTripsController>().fetchActiveTrips();
    }
  }

  int _resumeSeq = 0;

  bool get _pickupFollowsCurrentLocation =>
      currentTab.value == 0 &&
      !isMapSelectionMode.value &&
      !_routeSummaryOpen &&
      (pickupAddress.value == 'Locating...' || isPickupCurrent);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final seq = ++_resumeSeq;
    final bool refreshPickup = _pickupFollowsCurrentLocation;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (seq != _resumeSeq) return;
      _reconnectSocketIfNeeded();
      reconcileActiveTrips();
      if (Get.isRegistered<TripStateService>()) {
        Get.find<TripStateService>().reconcileActiveTripStage();
      }
      if (refreshPickup) _getCurrentLocation();
    });
  }

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _setupTripStateSync();
    try {
      await checkRequirements(false);
    } finally {
      isInitialLoading.value = false;
    }

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) {
          checkRequirements(false);
          fetchNearbyDrivers();
          reconcileActiveTrips();
          _getCurrentLocation();
          _reconnectSocketIfNeeded();
        }
      });
    }

    _initSocketConnection();

    connectivitySubscription = Connectivity().onConnectivityChanged.listen((event) {
      checkRequirements(false);
    });

    locationSubscription = Geolocator.getServiceStatusStream().listen((status) {
      checkRequirements(false);
      if (status == ServiceStatus.enabled) {
        _getCurrentLocation();
      }
    });

    ever(currentLocation, (LatLng loc) {
      const defaultLatLng = LatLng(11.0168, 76.9558);
      if (_homeCentered || loc == defaultLatLng) return;
      if (currentTab.value != 0 || isMapSelectionMode.value) return;
      _homeCentered = true;
      _centerHomeOnCurrentLocation();
    });

    ever(stops, (_) {
      if (destinationAddress.value != 'Where to?') getRoute();
    });

    LocationService.mapKey();

    loadCurrentLocation();
    loadRecentSearches();
    maybeShowHomeCoachMarks();
  }

  bool _homeCentered = false;

  void clearRouteOverlay() {
    polylines.clear();
    markers.removeWhere((m) => m.markerId == const MarkerId('pickup') || m.markerId == const MarkerId('destination'));
    markers.refresh();
    destinationAddress.value = 'Where to?';
    destinationLatLng.value = const LatLng(11.0168, 76.9558);
    stops.clear();
    distance.value = '';
    duration.value = '';
    isSelectingPickup.value = true;
    selectedAirport.value = null;
    selectedTerminal.value = null;
  }

  void resetTripSelection() {
    destinationAddress.value = 'Where to?';
    destinationLatLng.value = const LatLng(11.0168, 76.9558);
    stops.clear();
    polylines.clear();
    distance.value = '';
    duration.value = '';
    isSelectingPickup.value = true;
    selectedAirport.value = null;
    selectedTerminal.value = null;
    markers.removeWhere((m) => m.markerId == const MarkerId('destination'));
    markers.refresh();
  }

  void _setupTripStateSync() {
    final tripStateService = Get.find<TripStateService>();
    ever(pickupAddress, (String val) {
      if (isMapSelectionMode.value) return;
      if (val != 'Locating...') {
        tripStateService.setLocations(pickup: val, destination: destinationAddress.value);
        _maybeGoToRouteSummary();
      }
    });

    ever(destinationAddress, (String val) {
      if (isMapSelectionMode.value) return;
      if (val != 'Where to?') {
        tripStateService.setLocations(pickup: pickupAddress.value, destination: val);
        _maybeGoToRouteSummary();
      }
    });

    ever(distance, (String val) {
      if (val.isNotEmpty) {
        final distDouble = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        tripStateService.setDistanceAndDuration(distance: distDouble, duration: duration.value);
      }
    });

    ever(duration, (String val) {
      if (val.isNotEmpty) {
        final distDouble = double.tryParse(distance.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        tripStateService.setDistanceAndDuration(distance: distDouble, duration: val);
      }
    });
  }

  Future<void> setMapStyle([GoogleMapController? mapController]) async {
    final controller = mapController ?? googleMapController;
    if (controller == null) return;
    try {
      final style = await rootBundle.loadString('assets/map_style.json');
      // ignore: deprecated_member_use
      await controller.setMapStyle(style);
    } catch (_) {}
  }

  static const List<Duration> _socketRetryBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
  ];

  Future<void> _initSocketConnection() async {
    for (int attempt = 0; attempt <= _socketRetryBackoff.length; attempt++) {
      final String? token = await SecureStorageService.getAuthToken();

      if (token != null && token.isNotEmpty) {
        SocketService().connect(token);
        Get.find<ChatUnreadService>().bindSocket();
        return;
      }

      if (attempt == _socketRetryBackoff.length) {
        return;
      }

      final delay = _socketRetryBackoff[attempt];
      await Future.delayed(delay);
      if (isClosed) return;
    }
  }

  Future<void> _reconnectSocketIfNeeded() async {
    final socketService = SocketService();
    // final bool healthy = socketService.isConnected;

    final String? token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      return;
    }
    socketService.connect(token);
    Get.find<ChatUnreadService>().bindSocket();
  }

  Future<void> zoomToFitRoute({bool retry = true, double padding = 100}) async {
    if (_routeSummaryOpen) return;
    if (googleMapController == null || markers.isEmpty) {
      return;
    }

    final bounds = getBounds(markers.map((m) => m.position).toList());
    try {
      await googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    } catch (_) {
      if (retry) {
        await Future.delayed(const Duration(milliseconds: 400));
        await zoomToFitRoute(retry: false, padding: padding);
      }
    }
  }

  List<LatLng> _decodeRoutePoints(Map<dynamic, dynamic> route) {
    final List<LatLng> coords = [];

    final legs = route['legs'];
    if (legs is List) {
      for (final leg in legs) {
        final steps = (leg is Map ? leg['steps'] : null);
        if (steps is! List) continue;
        for (final step in steps) {
          final poly = (step is Map ? step['polyline'] : null);
          final pts = (poly is Map ? poly['points'] : null)?.toString();
          if (pts == null || pts.isEmpty) continue;
          coords.addAll(PolylinePoints.decodePolyline(pts).map((p) => LatLng(p.latitude, p.longitude)));
        }
      }
    }

    if (coords.isEmpty) {
      final overview = (route['overview_polyline'] is Map ? route['overview_polyline']['points'] : null)?.toString();
      if (overview != null && overview.isNotEmpty) {
        coords.addAll(PolylinePoints.decodePolyline(overview).map((p) => LatLng(p.latitude, p.longitude)));
      }
    }

    return coords;
  }

  String? lastRouteError;

  Future<List<LatLng>> getRouteCoords(LatLng from, LatLng to, {List<LatLng> waypoints = const []}) async {
    try {
      final directions = await _locationService.getDirections(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
        waypoints: waypoints,
      );
      if (directions == null) {
        lastRouteError = 'no response (network/key/timeout)';
        return [];
      }
      if (directions['status'] != 'OK') {
        lastRouteError = '${directions['status']} ${directions['error_message'] ?? ''}'.trim();
        return [];
      }
      final routes = directions['routes'] as List;
      if (routes.isEmpty) {
        lastRouteError = 'OK but zero routes';
        return [];
      }
      final points = _decodeRoutePoints(routes[0] as Map);
      if (points.isEmpty) {
        lastRouteError = 'OK but polyline decoded empty';
        return [];
      }
      lastRouteError = null;
      return points;
    } catch (e) {
      lastRouteError = 'exception: $e';
      return [];
    }
  }

  Future<void> getRoute() async {
    try {
      if (pickupLatLng.value.latitude == 11.0168 && pickupLatLng.value.longitude == 76.9558 ||
          destinationLatLng.value.latitude == 11.0168 && destinationLatLng.value.longitude == 76.9558) {}

      if (destinationAddress.value == 'Where to?') {
        return;
      }

      distance.refresh();
      duration.refresh();

      final List<LatLng> waypoints = stops
          .map((s) => LatLng(double.tryParse('${s['lat']}') ?? 0, double.tryParse('${s['lng']}') ?? 0))
          .where((p) => p.latitude != 0 && p.longitude != 0)
          .toList();

      final directions = await _locationService.getDirections(
        pickupLatLng.value.latitude,
        pickupLatLng.value.longitude,
        destinationLatLng.value.latitude,
        destinationLatLng.value.longitude,
        waypoints: waypoints,
      );

      if (directions == null) {
        return;
      }

      if (directions['status'] != 'OK') {
        return;
      }

      final routes = directions['routes'] as List;
      if (routes.isEmpty) {
        return;
      }

      final legs = routes[0]['legs'] as List;

      if (legs.isNotEmpty) {
        double totalMeters = 0;
        int totalSeconds = 0;
        for (final leg in legs) {
          totalMeters += ((leg['distance']?['value']) as num?)?.toDouble() ?? 0;
          totalSeconds += ((leg['duration']?['value']) as num?)?.toInt() ?? 0;
        }
        distance.value = totalMeters > 0
            ? '${(totalMeters / 1000).toStringAsFixed(1)} km'
            : (legs[0]['distance']?['text']?.toString() ?? '0 km');
        duration.value = totalSeconds > 0
            ? formatDuration((totalSeconds / 60).round())
            : (legs[0]['duration']?['text']?.toString() ?? '0 mins');

        distance.refresh();
        duration.refresh();
      }

      final List<LatLng> routeCoords = _decodeRoutePoints(routes[0] as Map);

      polylines.assignAll({
        Polyline(
          polylineId: const PolylineId('route_casing'),
          points: routeCoords,
          color: AppColors.info.withAlpha(10),
          width: 9,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 0,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: routeCoords,
          color: AppColors.info,
          width: 2,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 1,
        ),
      });
      polylines.refresh();
      await loadCustomMarkers();

      await zoomToFitRoute();
    } catch (_) {}
  }

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? stopIcon;

  Future<BitmapDescriptor> _loadIcon(String path, double size, {double? hue}) async {
    try {
      return await BitmapDescriptor.asset(ImageConfiguration(size: Size(size, size)), path);
    } catch (_) {
      return hue != null ? BitmapDescriptor.defaultMarkerWithHue(hue) : BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> loadCustomMarkers() async {
    pickupIcon ??= await _loadIcon("assets/icons/pickup_marker.png", 48);
    destinationIcon ??= await _loadIcon("assets/icons/destination_marker.png", 48);
    stopIcon ??= await _loadIcon("assets/icons/stop_pin.png", 40, hue: BitmapDescriptor.hueOrange);

    final List<Marker> stopMarkers = [];
    for (final e in stops.asMap().entries) {
      final lat = double.tryParse('${e.value['lat']}') ?? 0;
      final lng = double.tryParse('${e.value['lng']}') ?? 0;
      if (lat == 0 || lng == 0) continue;
      final int n = e.key + 1;
      final icon = stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      stopMarkers.add(
        Marker(
          markerId: MarkerId('stop_${e.key}'),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: InfoWindow(title: 'Stop $n'),
        ),
      );
    }

    markers.assignAll({
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng.value,
        icon: pickupIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: pickupAddress.value == 'Locating...' ? 'Pickup' : pickupAddress.value),
      ),
      ...stopMarkers,
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationLatLng.value,
        icon: destinationIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: destinationAddress.value == 'Where to?' ? 'Destination' : destinationAddress.value,
        ),
      ),
    });
    markers.refresh();
  }

  Future<void> fetchNearbyDrivers() async {
    try {
      final loc = currentLocation.value;
      final tripsRepo = TripsRepository();
      final response = await tripsRepo.getNearbyDrivers(loc.latitude, loc.longitude);
      if (response == null || response['data'] == null) return;

      final drivers = response['data']['drivers'] as Map<String, dynamic>?;
      if (drivers == null) return;

      onlineDriverIcon ??= await _svgToBitmap('assets/icons/car_top_online.svg');
      onrideDriverIcon ??= await _svgToBitmap('assets/icons/car_top_onride.svg');
      offlineDriverIcon ??= await _svgToBitmap('assets/icons/car_top_offline.svg');

      final Set<Marker> newMarkers = {};

      for (final status in ['online', 'onride', 'offline']) {
        final list = drivers[status];
        if (list is! List) continue;
        final icon = status == 'online'
            ? onlineDriverIcon
            // : status == 'onride'
            : onrideDriverIcon;
        // : offlineDriverIcon;
        for (int i = 0; i < list.length; i++) {
          final d = list[i] as Map<String, dynamic>;
          final coords = _extractLatLng(d);
          if (coords == null) continue;
          final id = d['id']?.toString() ?? d['driverId']?.toString() ?? '$status$i';
          newMarkers.add(
            Marker(
              markerId: MarkerId('driver_$id'),
              position: coords,
              icon: icon ?? BitmapDescriptor.defaultMarker,
              anchor: const Offset(0.5, 0.5),
              flat: true,
            ),
          );
        }
      }

      driverMarkers.assignAll(newMarkers);
      driverMarkers.refresh();
    } catch (_) {}
  }

  Future<BitmapDescriptor> _svgToBitmap(String asset, {double size = 22}) async {
    final String rawSvg = await rootBundle.loadString(asset);
    final pictureInfo = await vg.loadPicture(SvgStringLoader(rawSvg), null);

    final double dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final scale = (size * dpr) / pictureInfo.size.width;
    final width = (size * dpr).toInt();
    final height = (pictureInfo.size.height * scale).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);

    final image = await recorder.endRecording().toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  }

  LatLng? _extractLatLng(Map<String, dynamic> d) {
    final dynamic lat = d['lat'] ?? d['latitude'] ?? d['location']?['lat'];
    final dynamic lng = d['lng'] ?? d['longitude'] ?? d['location']?['lng'];
    final dLat = double.tryParse(lat?.toString() ?? '');
    final dLng = double.tryParse(lng?.toString() ?? '');
    if (dLat == null || dLng == null) return null;
    return LatLng(dLat, dLng);
  }

  LatLngBounds getBounds(List<LatLng> points) {
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  Future<void> loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          AppSnackbar.error('Permission Denied', 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppSnackbar.error('Permission Denied', 'Location permission permanently denied');
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final lastLatLng = LatLng(lastKnown.latitude, lastKnown.longitude);
        pickupLatLng.value = lastLatLng;
        currentLocation.value = lastLatLng;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final latLng = LatLng(position.latitude, position.longitude);

      pickupLatLng.value = latLng;
      currentLocation.value = latLng;

      String address = '';

      try {
        final result = await _locationService.getAddressFromLatLng(latLng.latitude, latLng.longitude);

        if (result != null && result.trim().isNotEmpty) {
          address = result;
        }
      } catch (e) {
        Logger().e('Address conversion failed', error: e);
      }

      if (address.isNotEmpty) {
        pickupAddress.value = address;
        await moveToLocation(latLng, address, isPickup: true, saveToRecent: false);
      }

      fetchNearbyDrivers();
    } catch (e) {
      AppSnackbar.error('Error', 'Failed to fetch current location');
    }
  }

  Future<void> loadRecentSearches() async {
    final searches = await LocalStorageService.getRecentSearches();
    recentSearches.assignAll(searches);
  }

  Future<void> clearRecentSearches() async {
    await LocalStorageService.clearRecentSearches();
    recentSearches.clear();
  }

  Future<void> loadSavedAddresses() async {
    final addresses = await LocalStorageService.getSavedAddresses();
    savedAddresses.assignAll(addresses);
  }

  Future<void> saveSavedAddress(String type, Map<String, dynamic> data) async {
    await LocalStorageService.saveSavedAddress(type, data);
    await loadSavedAddresses();
  }

  void editSavedAddress(String type) {
    editingSavedAddressType = type;
    goToSearch(isSelectingPickup.value);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      pickupLatLng.value = latLng;
      currentLocation.value = latLng;

      final address = await _locationService.getAddressFromLatLng(latLng.latitude, latLng.longitude);

      if (address != null) {
        pickupAddress.value = address;
      }

      if (googleMapController != null && !_routeSummaryOpen) {
        await googleMapController!.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 15)),
        );
      }
      fetchNearbyDrivers();
    } catch (_) {}
  }

  void onMapCreated(GoogleMapController controller) {
    googleMapController = controller;

    const defaultLatLng = LatLng(11.0168, 76.9558);
    if (currentLocation.value != defaultLatLng && !_routeSummaryOpen) {
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation.value, zoom: 14)));
    }
    fetchNearbyDrivers();
  }

  final RxBool isHomeMapReady = false.obs;

  void onHomeMapCreated(GoogleMapController controller) {
    homeMapController = controller;
    googleMapController = controller;
    _centerHomeOnCurrentLocation();
    fetchNearbyDrivers();
    Future.delayed(const Duration(milliseconds: 400), () => isHomeMapReady.value = true);
  }

  void _centerHomeOnCurrentLocation() {
    const defaultLatLng = LatLng(11.0168, 76.9558);
    if (currentLocation.value == defaultLatLng) return;
    homeMapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation.value, zoom: 14)),
    );
  }

  void goToSearch(bool isPickup) {
    setSelectingPickup(isPickup, moveCamera: false);
    Get.toNamed(AppRoutes.locationSearch, arguments: isPickup ? 'Pickup' : 'Destination');
  }

  void onCameraMove(CameraPosition position) {
    if (isAnimating) return;

    if (isSelectingPickup.value) {
      pickupLatLng.value = position.target;
    } else {
      destinationLatLng.value = position.target;
    }
  }

  void onCameraIdle() async {
    if (isAnimating) {
      isAnimating = false;
      return;
    }

    if (!shouldReverseGeocode) {
      shouldReverseGeocode = true;
      return;
    }

    try {
      String? address;

      if (isSelectingPickup.value) {
        address = await _locationService.getAddressFromLatLng(
          pickupLatLng.value.latitude,
          pickupLatLng.value.longitude,
        );

        if (address != null) {
          pickupAddress.value = address;
        }
      } else {
        address = await _locationService.getAddressFromLatLng(
          destinationLatLng.value.latitude,
          destinationLatLng.value.longitude,
        );

        if (address != null) {
          destinationAddress.value = address;
        }
      }
    } catch (_) {}
  }

  Future<void> setSelectingPickup(bool value, {bool moveCamera = true}) async {
    isSelectingPickup.value = value;
    shouldReverseGeocode = false;
    if (!moveCamera) return;

    isAnimating = true;

    try {
      if (googleMapController != null) {
        await googleMapController!.animateCamera(
          CameraUpdate.newLatLng(value ? pickupLatLng.value : destinationLatLng.value),
        );
      }
      isAnimating = false;
    } catch (e) {
      isAnimating = false;
    }
  }

  Future<void> moveToLocation(
    LatLng latLng,
    String address, {
    Map<String, dynamic>? searchData,
    bool? isPickup,
    bool saveToRecent = true,
  }) async {
    shouldReverseGeocode = false;
    isAnimating = true;

    if (editingSavedAddressType == null) {
      bool targetIsPickup = isPickup ?? isSelectingPickup.value;
      if (targetIsPickup) {
        pickupLatLng.value = latLng;
        pickupAddress.value = address;
      } else {
        destinationLatLng.value = latLng;
        destinationAddress.value = address;
      }
    }

    try {
      final Map<String, dynamic> dataToSave =
          searchData ??
          {
            'placeId': DateTime.now().millisecondsSinceEpoch.toString(),
            'mainText': address,
            'secondaryText': '',
            'lat': latLng.latitude,
            'lng': latLng.longitude,
          };

      if (editingSavedAddressType != null) {
        await saveSavedAddress(editingSavedAddressType!, dataToSave);
        editingSavedAddressType = null;
      }

      if (saveToRecent) {
        await LocalStorageService.saveRecentSearch(dataToSave);
        await loadRecentSearches();
      }

      isAnimating = false;
    } catch (e) {
      isAnimating = false;
    }
  }

  bool _proceeding = false;
  bool _routeSummaryOpen = false;
  void setRouteSummaryOpen(bool open) => _routeSummaryOpen = open;
  bool get isRoutingToSummary => _proceeding;

  void _clearProceedingSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _proceeding = false);
  }

  void _maybeGoToRouteSummary() {
    if (pickupAddress.value == 'Locating...' || destinationAddress.value == 'Where to?') return;
    _proceedToRouteSummary();
  }

  Future<void> _proceedToRouteSummary() async {
    if (_proceeding) return;
    if (Get.currentRoute == AppRoutes.routeSummary) return;
    _proceeding = true;

    final bool onSearch = Get.currentRoute == AppRoutes.locationSearch;

    if (onSearch && _routeSummaryOpen) {
      Get.back();
      _clearProceedingSoon();
      return;
    }
    distance.value = '';
    duration.value = '';
    final Future<dynamic>? nav = onSearch ? Get.offNamed(AppRoutes.routeSummary) : Get.toNamed(AppRoutes.routeSummary);

    bool ok = false;
    try {
      final vsc = Get.put(VehicleSelectionController());
      final tripCtrl = Get.find<TripController>();
      ok = await vsc.fetchEstimation(
        pickUp: pickupAddress.value,
        drop: destinationAddress.value,
        stops: formattedStops,
        pickupDateTime: DateTime.now(),
        serviceTypeId: tripCtrl.serviceId,
        pickupLat: pickupLatLng.value.latitude,
        pickupLng: pickupLatLng.value.longitude,
        dropLat: destinationLatLng.value.latitude,
        dropLng: destinationLatLng.value.longitude,
      );
    } finally {
      _proceeding = false;
    }

    if (!ok && Get.currentRoute == AppRoutes.routeSummary) {
      Get.back();
    }

    await nav;
    resetTripSelection();
    googleMapController = homeMapController;
    _centerHomeOnCurrentLocation();
  }

  void changeTab(int index) {
    if (currentTab.value == 1 && index != 1 && Get.isRegistered<MyTripsController>()) {
      Get.find<MyTripsController>().clearFilters();
    }
    currentTab.value = index;
    if (index == 0) reconcileActiveTrips();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _coachTripDataWorker?.dispose();
    super.onClose();
  }

  Future<void> confirmMapLocation() async {
    final LatLng targetLatLng = isSelectingPickup.value ? pickupLatLng.value : destinationLatLng.value;
    final String targetAddress = isSelectingPickup.value ? pickupAddress.value : destinationAddress.value;

    if (targetAddress == 'Locating...' ||
        targetAddress.isEmpty ||
        (!isSelectingPickup.value && targetAddress == 'Where to?')) {
      AppSnackbar.info("Please wait", "Loading location address...");
      return;
    }

    isMapSelectionMode.value = false;
    await moveToLocation(targetLatLng, targetAddress, isPickup: isSelectingPickup.value);
    if (Get.isRegistered<TripStateService>()) {
      Get.find<TripStateService>().setLocations(pickup: pickupAddress.value, destination: destinationAddress.value);
    }
    _maybeGoToRouteSummary();
  }

  Future<void> checkRequirements(bool isRetry) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasNetwork = connectivityResult.any((result) => result != ConnectivityResult.none);

    bool currentInternet = false;
    if (hasNetwork) {
      try {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
        currentInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException {
        currentInternet = false;
      } on TimeoutException {
        currentInternet = false;
      }
    }
    hasInternet.value = currentInternet;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    isLocationServiceEnabled.value = serviceEnabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      if (isRetry) AppSnackbar.error("Location Permission Denied", "Please enable location permission");
    }

    hasLocationPermission.value =
        !(permission == LocationPermission.denied || permission == LocationPermission.deniedForever);
  }

  Future<void> handleTripDetailsTap(BuildContext context) async {
    final activeTripsController = Get.find<ActiveTripsController>();
    final tripStateService = Get.find<TripStateService>();

    if (activeTripsController.displayTrips.isEmpty) {
      Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.primary)), barrierDismissible: false);
      await activeTripsController.fetchActiveTrips();
      if (Get.isDialogOpen == true) Get.back();
    } else {
      activeTripsController.fetchActiveTrips();
    }

    final trips = activeTripsController.displayTrips;

    if (trips.isEmpty) {
      tripStateService.resetToDummy();
      AppSnackbar.info('No Active Trips', 'You do not have any ongoing trips.');
    } else if (trips.length == 1) {
      final trip = trips.first;
      if (trip['_localPending'] == true && tripStateService.switchTrip(trip['_id'].toString())) {
        tripStateService.entrySource.value = 'ongoing';
        tripStateService.resumeRideFlow();
      } else {
        resumeTripFromData(Map<String, dynamic>.from(trip));
      }
    } else {
      await Get.toNamed(AppRoutes.activeTrips);
    }
  }

  String formatDuration(int totalMinutes) {
    final int days = totalMinutes ~/ (24 * 60);
    final int hours = (totalMinutes % (24 * 60)) ~/ 60;
    final int minutes = totalMinutes % 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} $hours hr${hours > 1 ? 's' : ''}';
    }

    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} $minutes min${minutes > 1 ? 's' : ''}';
    }

    return '$minutes min${minutes > 1 ? 's' : ''}';
  }

  String _vehicleType(Map trip) {
    final candidates = [
      trip['enquiryData']?['vehicles']?[0]?['vehicle_type'],
      trip['enquiryData']?['vehicles']?[0]?['name'],
      trip['vehicle'],
      trip['selectedTariffId'],
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
      if (c is Map) {
        final v = c['vehicle_type'] ?? c['name'] ?? c['type'];
        if (v != null) return v.toString();
      }
    }
    return 'Mini';
  }

  Map fareBreakdown(Map trip) {
    final completed = (trip['status']?.toString().toLowerCase() ?? '') == 'completed';
    final primary = completed ? trip['afterTripBreakdowns'] : trip['beforeTripBreakdowns'];
    if (primary is Map && primary['customerFareBreakDown'] is Map) return primary['customerFareBreakDown'] as Map;
    final alt = completed ? trip['beforeTripBreakdowns'] : trip['afterTripBreakdowns'];
    if (alt is Map && alt['customerFareBreakDown'] is Map) return alt['customerFareBreakDown'] as Map;
    if (trip['customerFareBreakDown'] is Map) return trip['customerFareBreakDown'] as Map;
    return const {};
  }

  double _fareD(Map trip, String key) {
    final fare = fareBreakdown(trip);
    return double.tryParse((fare[key] ?? trip[key])?.toString() ?? '') ?? 0.0;
  }

  String _asAddress(dynamic v, [String fallback = 'Unknown']) {
    if (v == null) return fallback;
    if (v is String) return v.isEmpty ? fallback : v;
    if (v is Map) {
      return (v['address'] ?? v['formattedAddress'] ?? v['name'] ?? v['label'] ?? fallback).toString();
    }
    return v.toString();
  }

  double? _coord(Map<String, dynamic> trip, List<List<String>> paths) {
    for (final path in paths) {
      dynamic cur = trip;
      for (final key in path) {
        if (cur is Map && cur.containsKey(key)) {
          cur = cur[key];
        } else {
          cur = null;
          break;
        }
      }
      final v = double.tryParse(cur?.toString() ?? '');
      if (v != null) return v;
    }
    return null;
  }

  void resumeTripFromData(Map<String, dynamic> trip) {
    try {
      final tripStateService = Get.find<TripStateService>();
      tripStateService.entrySource.value = 'ongoing';
      final Map<String, dynamic>? driver = trip['driver'];

      final vehicleObj = trip['vehicle'];
      final String vehicleType = (trip['vehicleType'] ?? _vehicleType(trip)).toString();
      final String? vehicleModel =
          (trip['vehicleName'] ?? (vehicleObj is Map ? (vehicleObj['modelName'] ?? vehicleObj['name']) : null))
              ?.toString();
      final String? plateNumber = vehicleObj is Map ? vehicleObj['number']?.toString() : null;

      final double distance =
          double.tryParse(
            (trip['afterTripBreakdowns']?['fare']?['distance'] ??
                        trip['enquiryData']?['distance_km'] ??
                        trip['distanceKm'] ??
                        trip['distance'] ??
                        trip['distanceInKm'] ??
                        '0')
                    ?.toString()
                    .replaceAll('NaN', '0') ??
                '0',
          ) ??
          0.0;

      final int durationMinutes =
          int.tryParse(
            (trip['tripCompletedDuration'] ??
                        trip['enquiryData']?['duration_mins'] ??
                        trip['durationMinutes'] ??
                        trip['duration'] ??
                        trip['totalDuration'] ??
                        '0')
                    ?.toString() ??
                '0',
          ) ??
          0;

      final double finalAmount = double.tryParse(trip['finalAmount']?.toString() ?? '0') ?? 0.0;
      final double customerFinalAmount =
          double.tryParse(
            ((trip['afterTripBreakdowns']?['customerFareBreakDown']?['customerFinalAmount']) ??
                        (trip['beforeTripBreakdowns']?['customerFareBreakDown']?['customerFinalAmount']) ??
                        (trip['customerFareBreakDown']?['customerFinalAmount']) ??
                        trip['customerFinalAmount'])
                    ?.toString() ??
                '',
          ) ??
          finalAmount;

      final String tripId = (trip['bookingId'] ?? trip['_id'] ?? '').toString();
      final RideStage knownStage = tripStateService.activeStages[tripId] ?? RideStage.none;

      tripStateService.setBookingDetails(
        markFindingDriver: false,
        bookingId: tripId,
        status: (trip['status'] ?? 'scheduled').toString(),
        pickup: _asAddress(trip['pickupAddress']),
        drop: _asAddress(trip['dropoffAddress']),
        stops: TripDetailsModel.stopsFrom(trip['stops'] ?? trip['enquiryData']?['stops']),
        isRoundTrip: TripDetailsModel.roundTripFrom(
          trip['serviceName'] ?? trip['service_name'] ?? trip['serviceType'],
          flag: trip['isRoundTrip'],
          serviceId: trip['serviceId'] ?? trip['service_id'],
        ),
        pickupDateTime: trip['scheduledAt'] != null ? DateTime.parse(trip['scheduledAt'].toString()) : DateTime.now(),
        vehicleType: vehicleType.toString(),
        vehicleModel: vehicleModel,
        plateNumber: plateNumber,
        customerFinalAmount: customerFinalAmount,
        tripCompletedFinalAmount: double.tryParse(
          ((trip['afterTripBreakdowns']?['customerFareBreakDown']?['customerFinalAmount']) ??
                      (trip['afterTripBreakdowns']?['customerFareBreakDown']?['finalAmount']) ??
                      trip['tripCompletedFinalAmount'])
                  ?.toString() ??
              '',
        ),
        estimatedFare: _fareD(trip, 'estimatedFare'),
        pricePerKm: double.tryParse(trip['pricePerKm']?.toString() ?? ''),
        serviceTax: _fareD(trip, 'serviceTax'),
        tollAmount: _fareD(trip, 'tollAmount'),
        discountAmount: _fareD(trip, 'discountAmount'),
        driverAllowance: _fareD(trip, 'driverAllowance'),
        totalDriverCharges: _fareD(trip, 'totalDriverCharges'),
        totalExtraCharges: _fareD(trip, 'totalExtraCharges'),
        distance: distance,
        duration: formatDuration(durationMinutes),
        finalAmount: finalAmount,
        paymentMethod: (trip['paymentMethod'] ?? 'cash').toString(),
        paymentStatus: (trip['paymentStatus'] ?? 'pending').toString(),
        driverName: driver?['name']?.toString(),
        driverPhone: driver?['phone']?.toString(),
        driverImage: driverImageUrlFrom(driver),
        driverRating: double.tryParse((driver?['ratings'])?.toString() ?? ''),
        driverTrips: (driver?['tripCount'] ?? driver?['trips'])?.toString(),
        startOtp: trip['driverOtp']?.toString() ?? trip['startOtp']?.toString(),
        endOtp: trip['endOtp']?.toString(),
        pickupLat: _coord(trip, [
          ['pickupLat'],
          ['enquiryData', 'pickup', 'lat'],
          ['pickup', 'lat'],
        ]),
        pickupLng: _coord(trip, [
          ['pickupLng'],
          ['enquiryData', 'pickup', 'lng'],
          ['pickup', 'lng'],
        ]),
        dropLat: _coord(trip, [
          ['dropoffLat'],
          ['dropLat'],
          ['enquiryData', 'dropoff', 'lat'],
          ['dropoff', 'lat'],
        ]),
        dropLng: _coord(trip, [
          ['dropoffLng'],
          ['dropLng'],
          ['enquiryData', 'dropoff', 'lng'],
          ['dropoff', 'lng'],
        ]),
      );

      final statusStr = (trip['status']?.toString() ?? '').toLowerCase();

      RideStage? listStage;
      if (statusStr == 'booking accepted') {
        listStage = RideStage.findingDriver;
      } else if (statusStr == 'pickup arrived') {
        listStage = RideStage.tripVerification;
      } else if (statusStr == 'started') {
        listStage = RideStage.tripInProgress;
      } else if (statusStr == 'completed') {
        final paymentStatus = trip['paymentStatus']?.toString();
        listStage = TripStateService.isPaidStatus(paymentStatus) ? RideStage.tripCompleted : RideStage.payment;
      } else if (statusStr == 'cancelled') {
        listStage = RideStage.tripCancelled;
      } else {}

      if (listStage != null && tripStateService.stageRank(listStage) >= tripStateService.stageRank(knownStage)) {
        tripStateService.updateRideStage(listStage, bookingId: tripId);
      } else if (listStage != null) {}

      tripStateService.resumeRideFlow();
    } catch (e) {
      AppSnackbar.error('Error', 'Failed to resume trip: $e');
    }
  }
}
