import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/notification_service/notification_service.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/finding_driver_controller.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/payment_controller.dart';
import '../models/trip_details_model.dart';

enum RideStage { none, findingDriver, tripVerification, tripInProgress, tripCompleted, tripCancelled, payment }

String driverImageUrlFrom(dynamic driver) {
  if (driver is! Map) return '';
  final direct = (driver['driverImageUrl'] ?? '').toString().trim();
  if (direct.isNotEmpty) return direct;
  final di = driver['driverImage'];
  if (di is Map) return (di['imageUrl'] ?? '').toString().trim();
  if (di is String) return di.trim();
  return (driver['image'] ?? '').toString().trim();
}

class TripStateService extends GetxService with WidgetsBindingObserver {
  final RxString selectedBookingId = ''.obs;
  final RxMap<String, TripDetailsModel> activeTrips = <String, TripDetailsModel>{}.obs;
  final RxMap<String, RideStage> activeStages = <String, RideStage>{}.obs;
  final RxList<Map<String, dynamic>> lastBookingStops = <Map<String, dynamic>>[].obs;

  TripDetailsModel? lastFinishedTrip;
  TripDetailsModel? _pendingRating;
  TripDetailsModel? get pendingRating => _pendingRating;
  String? promoBookingId;
  String? promoCode;
  double promoDiscount = 0;

  void setPromo({required String bookingId, required String code, required double discount}) {
    promoBookingId = bookingId;
    promoCode = code;
    promoDiscount = discount;
  }

  void clearPromo() {
    promoBookingId = null;
    promoCode = null;
    promoDiscount = 0;
  }

  String? lastPaymentTxnId;
  String? lastPaymentBookingId;
  double lastPaidAmount = 0;
  String? socketPaymentMethod;
  DateTime? lastPaymentDate;

  TripDetailsModel? get selectedTrip => activeTrips[selectedBookingId.value];
  RideStage get selectedStage => activeStages[selectedBookingId.value] ?? RideStage.none;
  List<TripDetailsModel> get activeTripsList => activeTrips.values.toList();
  bool get hasMultipleTrips => activeTrips.length > 1;

  final RxBool allowVerificationPop = false.obs;
  bool suppressAutoNav = false;
  final Set<String> mutedAutoNavBookings = <String>{};
  void muteAutoNav(String bookingId) {
    if (bookingId.isNotEmpty) mutedAutoNavBookings.add(bookingId);
  }

  void unmuteAutoNav(String bookingId) => mutedAutoNavBookings.remove(bookingId);
  bool isAutoNavMuted(String bookingId) => mutedAutoNavBookings.contains(bookingId);

  final RxString entrySource = 'booking'.obs;

  int dispatchSeconds = 0;
  DateTime? dispatchStartAt;

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  final RxnDouble trackDistanceKm = RxnDouble();
  final RxnInt trackDurationMin = RxnInt();
  final RxnString noDriversBookingId = RxnString();

  DateTime? trackUpdatedAt;
  static const Duration trackFreshWindow = Duration(seconds: 90);
  bool get hasFreshTracking => trackUpdatedAt != null && DateTime.now().difference(trackUpdatedAt!) < trackFreshWindow;

  DateTime? _lastResumeSync;

  Future<void> handleAppResumed({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastResumeSync != null && now.difference(_lastResumeSync!) < const Duration(seconds: 3)) {
      return;
    }
    _lastResumeSync = now;

    await _drainPendingTripEvent();
    await ensureConnected();
    await reconcileActiveTripStage();
    await refreshDriverLocationFromApi();
  }

  Future<void> _drainPendingTripEvent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(NotificationService.pendingTripEventKey);
      if (raw == null || raw.isEmpty) return;
      await prefs.remove(NotificationService.pendingTripEventKey);

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final key in const ['bookingId', 'booking_id', 'tripId', 'trip_id', '_id']) {
        final String id = decoded[key]?.toString().trim() ?? '';
        if (id.isEmpty) continue;
        if (activeTrips.containsKey(id)) selectedBookingId.value = id;
        return;
      }
    } catch (_) {}
  }

  Future<void> refreshDriverLocationFromApi([String? bookingId]) async {
    final id = bookingId ?? selectedBookingId.value;
    if (id.isEmpty || id == 'pending_booking') return;
    try {
      final data = await _tripsRepository.getDriverLocation(id);
      final node = data?['data'] is Map ? data!['data'] : data;
      final pos = _latLngFrom(node) ?? _latLngFrom(node is Map ? node['driver'] : null);
      if (pos == null) {
        return;
      }
      updateDriverLocation(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  List<LatLng>? prewarmedRoute;
  String? prewarmedRouteKey;
  double? prewarmedRouteKm;
  int? prewarmedRouteMin;

  String routeCacheKey(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    return '$id:${legFor(id)}';
  }

  void cachePrewarmedRoute(List<LatLng>? coords, {double? km, int? min}) {
    final bool clearing = coords == null || coords.isEmpty;
    prewarmedRoute = clearing ? null : coords;
    prewarmedRouteKey = clearing ? null : routeCacheKey(null);
    prewarmedRouteKm = clearing ? null : km;
    prewarmedRouteMin = clearing ? null : min;
    _saveRouteCache();
  }

  final RxBool sosActive = false.obs;
  final RxBool showTripStops = false.obs;
  final Map<String, DateTime> driverArrivedAt = {};

  final SocketService _socketService = SocketService();
  final TripsRepository _tripsRepository = TripsRepository();
  bool _reconciling = false;
  Worker? _connWorker;
  Timer? _locationEmitTimer;
  static const Duration _locationEmitInterval = Duration(seconds: 5);

  SharedPreferences? _prefs;
  Timer? _saveDebounce;
  static const Duration _saveDebounceWindow = Duration(milliseconds: 250);

  Future<SharedPreferences> _prefsInstance() async => _prefs ??= await SharedPreferences.getInstance();

  void _scheduleSave() {
    _saveDebounce?.cancel();
    if (activeTrips.isEmpty) {
      _saveState();
      return;
    }
    _saveDebounce = Timer(_saveDebounceWindow, _saveState);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initializeService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    handleAppResumed();
  }

  Future<void> _initializeService() async {
    bindListeners();
    await _loadSavedState();
    await _drainPendingTripEvent();

    ever(activeStages, (_) => _scheduleSave());
    ever(activeTrips, (_) => _scheduleSave());
    ever(selectedBookingId, (_) => _scheduleSave());
    ever(activeStages, (Map<String, RideStage> stages) {
      if (stages.isEmpty) {
        _stopLocationEmit();
      } else {
        _startLocationEmit();
      }
    });

    if (Get.isRegistered<ConnectivityService>()) {
      _connWorker = ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (!reachable) return;
        ensureConnected();
        if (activeStages.isNotEmpty) reconcileActiveTripStage();
      });
    }

    await ensureConnected();

    if (activeStages.isNotEmpty) {
      _startLocationEmit();
      reconcileActiveTripStage();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationEmit();
    _connWorker?.dispose();
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce!.cancel();
      _saveState();
    }
    super.onClose();
  }

  void _startLocationEmit() {
    if (_locationEmitTimer != null) return;
    _emitCustomerLocation();
    _locationEmitTimer = Timer.periodic(_locationEmitInterval, (_) {
      if (activeStages.isEmpty) {
        _stopLocationEmit();
        return;
      }
      _emitCustomerLocation();
    });
  }

  void _stopLocationEmit() {
    _locationEmitTimer?.cancel();
    _locationEmitTimer = null;
  }

  void _emitCustomerLocation() {
    final socket = _socketService.socket;
    if (socket == null || socket.connected != true) return;
    final id = selectedBookingId.value;
    if (id.isEmpty || id == 'pending_booking') return;
    if (!Get.isRegistered<HomeController>()) return;
    final cust = Get.find<HomeController>().currentLocation.value;
    socket.emit('customer:location', {'latitude': cust.latitude, 'longitude': cust.longitude, 'tripId': id});
  }

  bool _looksLikeReturnLeg(dynamic data) {
    if (data is! Map) return false;
    for (final key in ['status', 'tripStatus', 'phase', 'legType']) {
      final v = (data[key] ?? '').toString().toLowerCase().replaceAll('_', ' ');
      if (v.contains('return')) return true;
    }
    return data['isReturnLeg'] == true || data['isReturn'] == true;
  }

  bool isRoundTripFor(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    final t = activeTrips[id];
    if (t == null) return false;
    return t.isRoundTrip == true || (t.isRoundTrip == null && t.dropDateTime != null);
  }

  int legFor(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    return (activeTrips[id]?.currentLeg ?? 1).clamp(1, 2);
  }

  bool get isSelectedRoundTrip => isRoundTripFor(null);
  int get selectedLeg => legFor(null);
  bool get isSelectedFinalLeg => !isSelectedRoundTrip || selectedLeg >= 2;

  bool isHaltedFor(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    if (!isRoundTripFor(id) || legFor(id) >= 2) return false;
    return activeTrips[id]?.haltStartedAt != null;
  }

  bool get isSelectedHalted => isHaltedFor(null);

  DateTime? haltStartFor(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    return activeTrips[id]?.haltStartedAt;
  }

  void beginHalt(String bookingId) {
    final t = activeTrips[bookingId];
    if (t == null) return;
    if (legFor(bookingId) >= 2) return;
    if (t.haltStartedAt != null) return;

    activeTrips[bookingId] = t.copyWith(
      haltStartedAt: DateTime.now(),
      isRoundTrip: true,
      clearEndOtp: true,
      originalPickupLat: t.originalPickupLat ?? t.pickupLat,
      originalPickupLng: t.originalPickupLng ?? t.pickupLng,
      originalPickupAddress: t.originalPickupAddress ?? t.pickupLocation,
      status: 'started',
    );
    trackDistanceKm.value = null;
    trackDurationMin.value = null;
    trackUpdatedAt = null;
    activeTrips.refresh();
    _scheduleSave();
  }

  LatLng? activeDestinationFor(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    final t = activeTrips[id];
    if (t == null) return null;

    if (isRoundTripFor(id) && legFor(id) >= 2) {
      final lat = t.originalPickupLat ?? t.pickupLat;
      final lng = t.originalPickupLng ?? t.pickupLng;
      if (lat != null && lng != null && !(lat == 0 && lng == 0)) return LatLng(lat, lng);
    }

    if (t.dropLat != null && t.dropLng != null) return LatLng(t.dropLat!, t.dropLng!);
    return null;
  }

  String? activeDestinationLabelFor(String? bookingId) {
    final id = bookingId ?? selectedBookingId.value;
    final t = activeTrips[id];
    if (t == null) return null;
    if (isRoundTripFor(id) && legFor(id) >= 2) {
      return t.originalPickupAddress ?? t.pickupLocation;
    }
    return t.destinationLocation;
  }

  void advanceToReturnLeg(String bookingId, {String? endOtp}) {
    final t = activeTrips[bookingId];
    if (t == null) return;
    if (legFor(bookingId) >= 2) return;

    activeTrips[bookingId] = t.copyWith(
      currentLeg: 2,
      isRoundTrip: true,
      clearHalt: true,
      endOtp: (endOtp != null && endOtp.isNotEmpty) ? endOtp : null,
      originalPickupLat: t.originalPickupLat ?? t.pickupLat,
      originalPickupLng: t.originalPickupLng ?? t.pickupLng,
      originalPickupAddress: t.originalPickupAddress ?? t.pickupLocation,
      status: 'started',
    );

    trackDistanceKm.value = null;
    trackDurationMin.value = null;
    trackUpdatedAt = null;
    driverArrivedAt.remove(bookingId);

    updateRideStage(RideStage.tripInProgress, bookingId: bookingId, legChanged: true);
  }

  int stageRank(RideStage s) {
    switch (s) {
      case RideStage.none:
        return 0;
      case RideStage.findingDriver:
        return 1;
      case RideStage.tripVerification:
        return 2;
      case RideStage.tripInProgress:
        return 3;
      case RideStage.tripCompleted:
      case RideStage.payment:
        return 4;
      case RideStage.tripCancelled:
        return 5;
    }
  }

  RideStage? _stageFromStatus(String? status, String? paymentStatus) {
    switch (status?.toLowerCase()) {
      case 'booking accepted':
      case 'booking confirmed':
        return RideStage.findingDriver;
      case 'pickup arrived':
        return RideStage.tripVerification;
      case 'started':
        return RideStage.tripInProgress;
      case 'completed':
        final paid = paymentStatus?.toLowerCase() == 'success' || isPaidStatus(paymentStatus);
        return paid ? RideStage.tripCompleted : RideStage.payment;
      case 'cancelled':
        return RideStage.tripCancelled;
      default:
        return null;
    }
  }

  Future<void> reconcileActiveTripStage() async {
    if (_reconciling) return;
    if (suppressAutoNav) return;
    final id = selectedBookingId.value;
    if (id.isEmpty || id == 'pending_booking') return;
    if (!activeStages.containsKey(id)) return;
    _reconciling = true;
    try {
      final trip = await _tripsRepository.getTripById(id);
      if (trip == null) return;

      final status = trip['status']?.toString();
      final paymentStatus = trip['paymentStatus']?.toString();

      final bool serverRoundTrip = TripDetailsModel.roundTripFrom(
        trip['serviceName'] ?? trip['service_name'] ?? trip['serviceType'],
        flag: trip['isRoundTrip'],
        serviceId: trip['serviceId'] ?? trip['service_id'],
      );
      final int? serverLeg = TripDetailsModel.legFrom(trip['currentLeg'] ?? trip['leg'] ?? trip['tripLeg']);

      if (serverRoundTrip || serverLeg != null) {
        final int? keptLeg = (serverLeg != null && serverLeg < legFor(id)) ? null : serverLeg;
        updateTripDetails(
          TripDetailsModel(bookingId: id, isRoundTrip: serverRoundTrip ? true : null, currentLeg: keptLeg),
          bookingId: id,
        );
      }

      final bool awaitingReturnLeg = isRoundTripFor(id) && legFor(id) < 2 && (serverLeg ?? 1) < 2;

      if (status?.toLowerCase() == 'completed' && awaitingReturnLeg && !_looksLikeReturnLeg(trip)) {
        beginHalt(id);
        updateRideStage(RideStage.tripInProgress, bookingId: id);
        return;
      }

      if (status?.toLowerCase() == 'completed' && isPaidStatus(paymentStatus)) {
        final dynamic afterCust = trip['afterTripBreakdowns'] is Map
            ? (trip['afterTripBreakdowns'] as Map)['customerFareBreakDown']
            : null;
        _settlePaidTrip(
          id,
          showReceipt: true,
          paidAmount: double.tryParse(
            ((afterCust is Map ? (afterCust['customerFinalAmount'] ?? afterCust['finalAmount']) : null) ??
                        trip['tripCompletedFinalAmount'] ??
                        trip['finalAmount'])
                    ?.toString() ??
                '',
          ),
          paidMethod: _methodFrom(trip),
        );
        return;
      }

      final String driverImg = driverImageUrlFrom(trip['driver']);
      final Map driverMap = trip['driver'] is Map ? trip['driver'] as Map : const {};
      final Map vehicleMap = trip['vehicle'] is Map ? trip['vehicle'] as Map : const {};

      String? nonEmpty(dynamic v) {
        final s = v?.toString().trim() ?? '';
        return (s.isEmpty || s == '0' || s == '_') ? null : s;
      }

      double? c(List<String> keys) {
        for (final k in keys) {
          final v = double.tryParse(trip[k]?.toString() ?? '');
          if (v != null && v != 0) return v;
        }
        return null;
      }

      updateTripDetails(
        TripDetailsModel(
          bookingId: id,
          status: status,
          paymentStatus: paymentStatus,
          startOtp: (trip['startOtp'] ?? trip['driverOtp'])?.toString(),
          endOtp: isHaltedFor(id) ? null : trip['endOtp']?.toString(),
          driverImage: driverImg.isNotEmpty ? driverImg : null,
          driverName: nonEmpty(driverMap['name']),
          driverPhone: nonEmpty(driverMap['phone']),
          driverRating: double.tryParse((driverMap['driverRating'] ?? driverMap['ratings'])?.toString() ?? ''),
          driverTrips: nonEmpty(driverMap['tripCount'] ?? driverMap['trips']),
          plateNumber: nonEmpty(vehicleMap['number'] ?? driverMap['vehiclePlate']),
          vehicleModel: nonEmpty(vehicleMap['modelName'] ?? vehicleMap['name'] ?? driverMap['vehicleModel']),
          vehicleType: nonEmpty(driverMap['vehicleType'] ?? vehicleMap['type']),
          pickupLat: c(['pickupLat']),
          pickupLng: c(['pickupLng']),
          dropLat: c(['dropoffLat', 'dropLat']),
          dropLng: c(['dropoffLng', 'dropLng']),
        ),
        bookingId: id,
      );

      if (status?.toLowerCase() == 'completed') {
        _mergeCompletedFare(id, trip);
      }

      final newStage = _stageFromStatus(status, paymentStatus);
      if (newStage == null) return;
      final current = activeStages[id] ?? RideStage.none;

      final driverNode = trip['driver'];
      final String driverName = (driverNode is Map ? (driverNode['name'] ?? '') : '').toString().trim();
      final bool hasAssignedDriver = driverName.isNotEmpty && driverName != '0';
      final bool reDispatched =
          newStage == RideStage.findingDriver && current != RideStage.findingDriver && !hasAssignedDriver;
      if (reDispatched || stageRank(newStage) >= stageRank(current)) {
        if (reDispatched && activeTrips.containsKey(id)) {
          activeTrips[id] = activeTrips[id]!.copyWith(
            driverName: '0',
            driverPhone: '-',
            plateNumber: '0',
            vehicleModel: 'Unknown',
            arrivalTime: '0 min',
          );
          driverLocation.value = null;
        }
        updateRideStage(newStage, bookingId: id);
      }
    } catch (_) {
    } finally {
      _reconciling = false;
    }
  }

  bool switchTrip(String bookingId) {
    if (activeTrips.containsKey(bookingId)) {
      selectedBookingId.value = bookingId;
      return true;
    }
    return false;
  }

  bool _listenersBound = false;
  String _targetIdFrom(dynamic primary, [dynamic secondary]) {
    for (final source in [primary, secondary]) {
      if (source is! Map) continue;
      for (final key in const ['bookingId', '_id']) {
        final value = source[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return selectedBookingId.value;
  }

  Future<void> ensureSocketConnectionAndListeners() async {
    bindListeners();
    await ensureConnected();
  }

  Future<bool> ensureConnected() async {
    final String? token = await SecureStorageService.getAuthToken();
    if (token == null) {
      return false;
    }

    _socketService.connect(token);
    return true;
  }

  void bindListeners() {
    if (_listenersBound) {
      return;
    }
    _listenersBound = true;

    _socketService.on('booking:accepted', (data) {
      final String targetId = _targetIdFrom(data);
      if (targetId.isEmpty) return;

      final String prevId = selectedBookingId.value;
      if (prevId != targetId && activeTrips.containsKey(prevId) && !activeTrips.containsKey(targetId)) {
        activeTrips[targetId] = activeTrips[prevId]!.copyWith(bookingId: targetId);
        final prevStage = activeStages[prevId];
        if (prevStage != null) activeStages[targetId] = prevStage;
        final prevArrivedAt = driverArrivedAt.remove(prevId);
        if (prevArrivedAt != null) driverArrivedAt[targetId] = prevArrivedAt;
        activeTrips.remove(prevId);
        activeStages.remove(prevId);
      }
      selectedBookingId.value = targetId;

      final driver = data['driver'] ?? {};
      setDriverDetails(
        bookingId: targetId,
        name: driver['name'] ?? 'Unknown Driver',
        rating: double.tryParse((driver['driverRating'] ?? driver['ratings'])?.toString() ?? '') ?? 0.0,
        trips: (driver['tripCount'] ?? driver['trips'])?.toString() ?? '0',
        arrivalTime: driver['arrivalTime']?.toString(),
        plateNumber: driver['vehiclePlate']?.toString() ?? '_',
        pinCode: driver['pinCode']?.toString() ?? '_',
        phone: driver['phone']?.toString() ?? '_',
        image: driverImageUrlFrom(driver),
        destination: activeTrips[targetId]?.destinationLocation ?? '_',
        distanceLeft: '${activeTrips[targetId]?.distanceInKm ?? 0.0} km',
        vehicleType: driver['vehicleType']?.toString() ?? '_',
      );
      updateTripDetails(
        TripDetailsModel(
          bookingId: targetId,
          vehicleModel: driver['vehicleModel']?.toString() ?? '_',
          vehicleType: driver['vehicleType']?.toString() ?? '_',
        ),
        bookingId: targetId,
      );

      final dLat = driver['lat'] ?? driver['latitude'] ?? data['lat'];
      final dLng = driver['lng'] ?? driver['longitude'] ?? data['lng'];
      if (dLat != null && dLng != null) {
        final lat = double.tryParse(dLat.toString());
        final lng = double.tryParse(dLng.toString());
        if (lat != null && lng != null) {
          driverLocation.value = LatLng(lat, lng);
          _updateDriverMarker(lat, lng);
        }
      }

      if (!activeStages.containsKey(targetId) || activeStages[targetId] == RideStage.findingDriver) {
        updateRideStage(RideStage.findingDriver, bookingId: targetId);
      }

      _hydrateTripDetails(targetId);
      AppSnackbar.success('Driver Assigned', '${driver['name'] ?? 'Your driver'} is on the way');
    });

    _socketService.on('driver:arrived', (data) {
      final String targetId = _targetIdFrom(data);
      if (targetId.isEmpty) return;

      selectedBookingId.value = targetId;
      unmuteAutoNav(targetId);

      driverArrivedAt[targetId] = DateTime.now();

      final otp = data['otp']?.toString() ?? '0000';
      final String message = data['message']?.toString() ?? 'Please confirm the otp to start the trip';
      updateTripDetails(
        TripDetailsModel(bookingId: targetId, startOtp: otp),
        bookingId: targetId,
      );
      updateRideStage(RideStage.tripVerification, bookingId: targetId);

      _hydrateTripDetails(targetId);
      AppSnackbar.success('Your driver has arrived', message);

      if (targetId == selectedBookingId.value &&
          Get.currentRoute != AppRoutes.tripVerification &&
          _serverHasOngoingTrip) {
        Get.offNamedUntil(AppRoutes.tripVerification, (route) => route.settings.name == AppRoutes.home);
      }
    });

    _socketService.on('trip:started', (data) {
      final String targetId = _targetIdFrom(data);
      if (targetId.isEmpty) return;

      selectedBookingId.value = targetId;
      unmuteAutoNav(targetId);

      final endOtp = (data['endOtp'] ?? data['end_otp'] ?? data['otp'])?.toString();
      if (endOtp != null && endOtp.isNotEmpty) {
        updateTripDetails(
          TripDetailsModel(bookingId: targetId, endOtp: endOtp),
          bookingId: targetId,
        );
      }

      trackDistanceKm.value = null;
      trackDurationMin.value = null;
      trackUpdatedAt = null;

      final int? pushedLeg = TripDetailsModel.legFrom(
        data['currentLeg'] ?? data['leg'] ?? data['tripLeg'] ?? data['legNumber'],
      );
      final bool returnLeg = pushedLeg == 2 || _looksLikeReturnLeg(data);

      if (returnLeg && isRoundTripFor(targetId)) {
        advanceToReturnLeg(targetId);
      } else {
        updateRideStage(RideStage.tripInProgress, bookingId: targetId);
      }

      _hydrateTripDetails(targetId);
      AppSnackbar.success(
        returnLeg ? 'Return Trip Started' : 'Trip Started',
        returnLeg ? 'Heading back to your pickup point' : 'Enjoy your ride',
      );
    });

    _socketService.on('trip:completed', (data) {
      final Map fare = data['trip'] is Map
          ? data['trip']
          : data['data'] is Map
          ? data['data']
          : data['booking'] is Map
          ? data['booking']
          : data is Map
          ? data
          : const {};

      final String targetId = _targetIdFrom(fare, data);
      if (targetId.isEmpty) return;

      selectedBookingId.value = targetId;

      final paymentStatus = (fare['paymentStatus'] ?? data['paymentStatus'])?.toString() ?? 'pending';

      final Map bd = (fare['afterTripBreakdowns'] ?? data['afterTripBreakdowns']) is Map
          ? ((fare['afterTripBreakdowns'] ?? data['afterTripBreakdowns'])['customerFareBreakDown'] is Map
                ? (fare['afterTripBreakdowns'] ?? data['afterTripBreakdowns'])['customerFareBreakDown'] as Map
                : const {})
          : (fare['customerFareBreakDown'] is Map ? fare['customerFareBreakDown'] as Map : const {});

      double? pick(List<String> keys) {
        for (final k in keys) {
          final v = double.tryParse((fare[k] ?? data[k] ?? bd[k])?.toString() ?? '');
          if (v != null && v > 0) return v;
        }
        return null;
      }

      final double? completed = pick(['tripCompletedFinalAmount']);
      final double? finalAmt = pick([
        'customerFinalAmount',
        'finalAmount',
        'price',
        'totalFare',
        'totalAmount',
        'amount',
      ]);

      updateTripDetails(
        TripDetailsModel(
          bookingId: targetId,
          paymentStatus: paymentStatus,
          finalAmount: finalAmt,
          customerFinalAmount: finalAmt,
          tripCompletedFinalAmount: completed,
          totalFare: completed ?? finalAmt,
          distanceInKm: pick(['tripCompletedDistance', 'distanceInKm', 'distance']),
          endOtp: (fare['endOtp'] ?? data['endOtp'])?.toString(),
        ),
        bookingId: targetId,
      );
      final int? pushedLeg = TripDetailsModel.legFrom(
        (fare['currentLeg'] ?? data['currentLeg'] ?? fare['leg'] ?? data['leg']),
      );
      final bool onwardLegDone = isRoundTripFor(targetId) && (pushedLeg ?? legFor(targetId)) < 2;

      if (onwardLegDone) {
        beginHalt(targetId);
        AppSnackbar.success('Destination Reached', 'Start the return journey whenever you are ready');
        return;
      }

      updateRideStage(RideStage.tripCompleted, bookingId: targetId);

      if (activeTrips[targetId] != null) lastFinishedTrip = activeTrips[targetId];
      _hydrateCompletedTrip(targetId);

      AppSnackbar.success('Trip Completed', 'Thanks for riding with us');
    });

    _socketService.on('payment:success', (data) {
      _clearAwaitingCash();
      _settlePaidTrip(_targetIdFrom(data), showReceipt: true, paidMethod: _methodFrom(data));
      AppSnackbar.success('Payment Successful', 'Your payment was received');
    });

    _socketService.on('payment:failed', (data) {
      AppSnackbar.error('Payment Failed', data['message']?.toString() ?? 'Please try again');
    });

    _socketService.on('trip:payment:status', (data) {
      if (data is! Map) return;
      final String status = (data['paymentStatus'] ?? '').toString().toLowerCase();

      if (status == 'paid' || isPaidStatus(status)) {
        _clearAwaitingCash();
        final amount = data['amount'];
        _settlePaidTrip(
          _targetIdFrom(data),
          showReceipt: true,
          paidAmount: double.tryParse(amount?.toString() ?? ''),
          paidMethod: _methodFrom(data),
        );
        AppSnackbar.success(
          'Payment Received',
          amount != null ? 'Payment of ₹$amount received' : 'Your payment was received',
        );
      } else if (status == 'failed') {
        AppSnackbar.error('Payment Failed', data['message']?.toString() ?? 'Please try again');
      }
    });

    _socketService.on('trip:end_otp_resent', (data) {
      if (data is! Map) return;
      final String targetId = _targetIdFrom(data);
      final endOtp = (data['endOtp'] ?? data['end_otp'] ?? data['otp'])?.toString();
      if (targetId.isEmpty || endOtp == null || endOtp.isEmpty) return;
      updateTripDetails(
        TripDetailsModel(bookingId: targetId, endOtp: endOtp),
        bookingId: targetId,
      );
      AppSnackbar.info('End-Trip OTP', 'Your driver requested the end-trip OTP again.');
    });

    _socketService.on('sos:ack', (data) {
      AppSnackbar.info('SOS Acknowledged', 'Help is on the way. Support has your alert.');
    });

    _socketService.on('offer:new', (data) {
      if (data is! Map) return;
      final title = data['title']?.toString() ?? 'New Offer';
      final body = data['body']?.toString() ?? 'A new offer is available for you!';
      AppSnackbar.success(title, body);
    });

    _socketService.on('refund:initiated', (data) {
      AppSnackbar.info('Refund Initiated', data['message']?.toString() ?? 'Your refund is being processed');
    });

    _socketService.on('refund:completed', (data) {
      AppSnackbar.success('Refund Completed', data['message']?.toString() ?? 'Refund credited to your account');
    });

    _socketService.on('booking:driver_cancelled', (data) {
      final String targetId = _targetIdFrom(data);
      if (targetId.isEmpty) return;

      if (activeTrips.containsKey(targetId)) {
        activeTrips[targetId] = activeTrips[targetId]!.copyWith(
          driverName: '0',
          driverPhone: '-',
          plateNumber: '0',
          vehicleModel: '_',
          arrivalTime: '0 min',
        );
      }
      selectedBookingId.value = targetId;

      driverLocation.value = null;
      markers.removeWhere((m) => m.markerId == const MarkerId('driver_location'));
      markers.refresh();

      updateRideStage(RideStage.findingDriver, bookingId: targetId);
      AppSnackbar.error('Driver Cancelled your trip', 'Looking for another driver');
    });

    _socketService.on('booking:no_drivers', (data) {
      final String targetId = _targetIdFrom(data);
      if (targetId.isEmpty) return;

      final message = data['message']?.toString() ?? 'No drivers available right now. Please try again.';

      suppressAutoNavFor(const Duration(seconds: 1));

      driverLocation.value = null;
      markers.removeWhere((m) => m.markerId == const MarkerId('driver_location'));
      markers.refresh();

      final bool wasSelected = targetId == selectedBookingId.value;
      noDriversBookingId.value = targetId;
      if (wasSelected && AppRoutes.tripFlowRoutes.contains(Get.currentRoute)) {
        Get.until((route) => route.settings.name == AppRoutes.home || route.isFirst);
      }

      removeTrip(targetId);
      if (Get.isRegistered<ActiveTripsController>()) {
        Get.find<ActiveTripsController>().markCancelled(targetId);
      }

      AppSnackbar.error('No drivers available', message);
    });

    _socketService.on('driver:location_update', (data) {
      if (data == null) return;
      final lat = double.tryParse((data['latitude'] ?? data['lat'])?.toString() ?? '');
      final lng = double.tryParse((data['longitude'] ?? data['lng'])?.toString() ?? '');
      if (lat == null || lng == null) return;
      updateDriverLocation(lat, lng);
    });

    _socketService.on('driver:location_updated', (data) {
      if (data != null && data['lat'] != null && data['lng'] != null) {
        final double lat = double.tryParse(data['lat'].toString()) ?? 0.0;
        final double lng = double.tryParse(data['lng'].toString()) ?? 0.0;
        updateDriverLocation(lat, lng);
      }
    });

    _socketService.on('trip:tracking', (data) {
      if (data is! Map) return;

      final LatLng? driverPos = _latLngFrom(data['driver']);
      if (driverPos != null) updateDriverLocation(driverPos.latitude, driverPos.longitude);

      double? km = double.tryParse(data['distanceKm']?.toString() ?? '');
      int? mins = double.tryParse(data['durationMin']?.toString() ?? '')?.round();

      if (km == null || km <= 0) {
        final LatLng? customerPos = _latLngFrom(data['customer']);
        if (driverPos != null && customerPos != null) km = _crowKm(driverPos, customerPos);
      }
      if ((mins == null || mins <= 0) && km != null) {
        mins = (km / _citySpeedKmh * 60).round();
      }

      trackDistanceKm.value = km == null ? null : (km > 0.1 ? km : 0.1);
      trackDurationMin.value = mins;
      trackUpdatedAt = DateTime.now();
    });
  }

  static const double _citySpeedKmh = 25;

  LatLng? _latLngFrom(dynamic node) {
    if (node is! Map) return null;
    final lat = double.tryParse((node['lat'] ?? node['latitude'])?.toString() ?? '');
    final lng = double.tryParse((node['lng'] ?? node['longitude'])?.toString() ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  double _crowKm(LatLng a, LatLng b) {
    const double earthKm = 6371;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earthKm * math.asin(math.sqrt(h));
  }

  void updateDriverLocation(double lat, double lng) {
    driverLocation.value = LatLng(lat, lng);
    _updateDriverMarker(lat, lng);
  }

  BitmapDescriptor? _driverIcon;
  LatLng? _lastDriverPos;
  double _driverBearing = 0.0;

  void _updateDriverMarker(double lat, double lng) async {
    final driverIcon = _driverIcon ??= await _loadDriverIcon();
    final pos = LatLng(lat, lng);
    if (_lastDriverPos != null) {
      final b = _bearingBetween(_lastDriverPos!, pos);
      if (b != null) _driverBearing = b;
    }
    _lastDriverPos = pos;

    markers.removeWhere((m) => m.markerId == const MarkerId('driver_location'));
    markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: pos,
        icon: driverIcon,
        rotation: _driverBearing,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ),
    );
    markers.refresh();
  }

  double? _bearingBetween(LatLng a, LatLng b) {
    if ((a.latitude - b.latitude).abs() < 1e-7 && (a.longitude - b.longitude).abs() < 1e-7) return null;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Future<BitmapDescriptor> _loadDriverIcon() async {
    try {
      final asset = await rootBundle.load('assets/icons/cartop.png');
      final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final target = (48 * dpr).round();
      final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List(), targetWidth: target);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.bytes(data!.buffer.asUint8List(), imagePixelRatio: dpr);
    } catch (_) {
      return BitmapDescriptor.asset(const ImageConfiguration(size: Size(48, 48)), 'assets/icons/driver_icon.png');
    }
  }

  static const String _activeTripsKey = 'active_trips_v2';
  static const String _activeStagesKey = 'active_stages_v2';
  static const String _selectedTripKey = 'selected_trip_v2';
  static const String _pendingRatingKey = 'pending_rating_v1';
  static const String _routeCacheKey = 'prewarmed_route_v1';

  Future<void> _saveRouteCache() async {
    try {
      final prefs = await _prefsInstance();
      final coords = prewarmedRoute;
      if (coords == null || coords.isEmpty || prewarmedRouteKey == null) {
        await prefs.remove(_routeCacheKey);
        return;
      }
      await prefs.setString(
        _routeCacheKey,
        jsonEncode({
          'key': prewarmedRouteKey,
          'km': prewarmedRouteKm,
          'min': prewarmedRouteMin,
          'pts': [
            for (final p in coords) [p.latitude, p.longitude],
          ],
        }),
      );
    } catch (_) {}
  }

  void _loadRouteCache(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_routeCacheKey);
      if (raw == null) return;
      final Map<String, dynamic> data = jsonDecode(raw);
      final List pts = data['pts'] as List? ?? const [];
      if (pts.isEmpty) return;
      prewarmedRoute = [for (final p in pts) LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())];
      prewarmedRouteKey = data['key']?.toString();
      prewarmedRouteKm = (data['km'] as num?)?.toDouble();
      prewarmedRouteMin = (data['min'] as num?)?.toInt();
    } catch (_) {}
  }

  Future<void> _savePendingRating(TripDetailsModel trip) async {
    _pendingRating = trip;
    try {
      final prefs = await _prefsInstance();
      await prefs.setString(_pendingRatingKey, jsonEncode(trip.toJson()));
    } catch (e) {
      debugPrint('savePendingRating error: $e');
    }
  }

  Future<void> clearPendingRating() async {
    _pendingRating = null;
    try {
      final prefs = await _prefsInstance();
      await prefs.remove(_pendingRatingKey);
    } catch (e) {
      debugPrint('clearPendingRating error: $e');
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await _prefsInstance();
      final stagesStr = prefs.getString(_activeStagesKey);
      final tripsStr = prefs.getString(_activeTripsKey);
      final selectedStr = prefs.getString(_selectedTripKey);

      final pendingStr = prefs.getString(_pendingRatingKey);
      if (pendingStr != null) {
        try {
          _pendingRating = TripDetailsModel.fromJson(jsonDecode(pendingStr));
        } catch (_) {}
      }

      if (stagesStr != null && tripsStr != null) {
        final Map<String, dynamic> stagesData = jsonDecode(stagesStr);
        final Map<String, dynamic> tripsData = jsonDecode(tripsStr);

        activeStages.clear();
        stagesData.forEach((key, value) {
          activeStages[key] = RideStage.values.firstWhere((e) => e.toString() == value, orElse: () => RideStage.none);
        });

        activeTrips.clear();
        tripsData.forEach((key, value) {
          activeTrips[key] = TripDetailsModel.fromJson(value);
        });

        if (selectedStr != null && activeTrips.containsKey(selectedStr)) {
          selectedBookingId.value = selectedStr;
        } else if (activeTrips.isNotEmpty) {
          selectedBookingId.value = activeTrips.keys.first;
        }
      }

      _loadRouteCache(prefs);
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await _prefsInstance();
      if (activeTrips.isEmpty) {
        await prefs.remove(_activeStagesKey);
        await prefs.remove(_activeTripsKey);
        await prefs.remove(_selectedTripKey);
      } else {
        final Map<String, String> stagesMap = {};
        activeStages.forEach((key, value) {
          stagesMap[key] = value.toString();
        });

        final Map<String, dynamic> tripsMap = {};
        activeTrips.forEach((key, value) {
          tripsMap[key] = value.toJson();
        });

        await prefs.setString(_activeStagesKey, jsonEncode(stagesMap));
        await prefs.setString(_activeTripsKey, jsonEncode(tripsMap));
        await prefs.setString(_selectedTripKey, selectedBookingId.value);
      }
    } catch (_) {}
  }

  void updateTripDetails(TripDetailsModel details, {String? bookingId}) {
    final targetId = bookingId ?? details.bookingId ?? selectedBookingId.value;
    if (targetId.isEmpty) return;

    final existing = activeTrips[targetId];
    if (existing == null) {
      if (details.driverName == null) {}
      activeTrips[targetId] = details;
      return;
    }

    final String? patchImage = (details.driverImage?.isNotEmpty ?? false) ? details.driverImage : null;
    final String? patchDuration =
        (details.duration != null && details.duration != '0 min' && details.duration!.isNotEmpty)
        ? details.duration
        : null;

    activeTrips[targetId] = existing.copyWith(
      stops: details.stops,
      isRoundTrip: details.isRoundTrip,
      currentLeg: details.currentLeg,
      originalPickupAddress: details.originalPickupAddress,
      originalPickupLat: details.originalPickupLat,
      originalPickupLng: details.originalPickupLng,
      pickupLocation: details.pickupLocation,
      destinationLocation: details.destinationLocation,
      pickupDateTime: details.pickupDateTime,
      dropDateTime: details.dropDateTime,
      distanceInKm: details.distanceInKm,
      tripCompletedDistance: details.tripCompletedDistance,
      pricePerKm: details.pricePerKm,
      vehicleType: details.vehicleType,
      vehicleModel: details.vehicleModel,
      driverName: details.driverName,
      driverImage: patchImage,
      plateNumber: details.plateNumber,
      startOtp: details.startOtp,
      passengerName: details.passengerName,
      passengerPhone: details.passengerPhone,
      pickupLat: details.pickupLat,
      pickupLng: details.pickupLng,
      dropLat: details.dropLat,
      dropLng: details.dropLng,
      bookingId: details.bookingId,
      status: details.status,
      duration: patchDuration,
      finalAmount: details.finalAmount,
      customerFinalAmount: details.customerFinalAmount,
      tripCompletedFinalAmount: details.tripCompletedFinalAmount,
      paymentMethod: details.paymentMethod,
      paymentStatus: details.paymentStatus,
      driverPhone: details.driverPhone,
      driverRating: details.driverRating,
      driverTrips: details.driverTrips,
      arrivalTime: details.arrivalTime,
      distanceLeft: details.distanceLeft,
      totalFare: details.totalFare,
      estimatedFare: details.estimatedFare,
      serviceTax: details.serviceTax,
      tollAmount: details.tollAmount,
      tipsAmount: details.tipsAmount,
      permitCharges: details.permitCharges,
      discountAmount: details.discountAmount,
      driverAllowance: details.driverAllowance,
      totalDriverCharges: details.totalDriverCharges,
      totalExtraCharges: details.totalExtraCharges,
      advanceAmount: details.advanceAmount,
      endOtp: details.endOtp,
      extraCharges: details.extraCharges,
    );
  }

  Future<void> refreshTripFare(String bookingId) => _hydrateCompletedTrip(bookingId);

  Future<void> _hydrateCompletedTrip(String bookingId) async {
    if (bookingId.isEmpty) return;
    try {
      final trip = await _tripsRepository.getTripById(bookingId);
      if (trip == null) return;
      _mergeCompletedFare(bookingId, trip);
    } catch (e) {
      debugPrint('_hydrateCompletedTrip error: $e');
    }
  }

  final Set<String> _hydrating = <String>{};

  Future<void> ensureDriverImage(String bookingId) => _hydrateTripDetails(bookingId, onlyIfImageMissing: true);

  Future<void> _hydrateTripDetails(String bookingId, {bool onlyIfImageMissing = false}) async {
    if (bookingId.isEmpty || bookingId == 'pending_booking') return;
    if (onlyIfImageMissing && (activeTrips[bookingId]?.driverImage ?? '').trim().isNotEmpty) return;
    if (_hydrating.contains(bookingId)) return;
    _hydrating.add(bookingId);
    try {
      final trip = await _tripsRepository.getTripById(bookingId);
      if (trip == null) return;

      String? nonEmpty(dynamic v) {
        final s = v?.toString().trim() ?? '';
        return (s.isEmpty || s == '0' || s == '_' || s == 'null') ? null : s;
      }

      final Map driverMap = trip['driver'] is Map ? trip['driver'] as Map : const {};
      final Map vehicleMap = trip['vehicle'] is Map ? trip['vehicle'] as Map : const {};
      final String url = driverImageUrlFrom(trip['driver']);

      updateTripDetails(
        TripDetailsModel(
          bookingId: bookingId,
          driverImage: url.isNotEmpty ? url : null,
          driverName: nonEmpty(driverMap['name']),
          driverPhone: nonEmpty(driverMap['phone']),
          driverRating: double.tryParse((driverMap['driverRating'] ?? driverMap['ratings'])?.toString() ?? ''),
          driverTrips: nonEmpty(driverMap['tripCount'] ?? driverMap['trips']),
          plateNumber: nonEmpty(vehicleMap['number'] ?? driverMap['vehiclePlate']),
          vehicleModel: nonEmpty(vehicleMap['modelName'] ?? vehicleMap['name'] ?? driverMap['vehicleModel']),
          vehicleType: nonEmpty(driverMap['vehicleType'] ?? vehicleMap['type']),
        ),
        bookingId: bookingId,
      );
    } catch (_) {
    } finally {
      _hydrating.remove(bookingId);
    }
  }

  String? _completedDuration(Map trip) {
    final int? mins = int.tryParse(trip['tripCompletedDuration']?.toString() ?? '');
    if (mins == null || mins <= 0) return null;
    if (Get.isRegistered<HomeController>()) return Get.find<HomeController>().formatDuration(mins);
    return '$mins min';
  }

  void _mergeCompletedFare(String bookingId, Map trip) {
    double? d(dynamic v) => double.tryParse(v?.toString() ?? '');
    Map asMap(dynamic v) => v is Map ? v : const {};

    final Map promo = asMap(trip['promoCode']);
    final String promoCodeStr = (promo['code'] ?? '').toString();
    final double promoAmt = d(promo['discountAmount']) ?? 0;
    if (promoCodeStr.isNotEmpty && promoAmt > 0) {
      setPromo(bookingId: bookingId, code: promoCodeStr, discount: promoAmt);
    }

    final Map after = asMap(trip['afterTripBreakdowns']);
    final Map afterFare = asMap(after['fare']);
    final Map cust = asMap(after['customerFareBreakDown']);

    final bool hasAfter = cust.isNotEmpty || afterFare.isNotEmpty;

    if (!hasAfter) {
      updateTripDetails(
        TripDetailsModel(
          bookingId: bookingId,
          pickupLocation: trip['pickupAddress']?.toString(),
          destinationLocation: trip['dropoffAddress']?.toString(),
          paymentStatus: trip['paymentStatus']?.toString(),
          paymentMethod: trip['paymentMethod']?.toString(),
        ),
        bookingId: bookingId,
      );
      return;
    }

    final double? afterFinal =
        d(cust['customerFinalAmount']) ??
        d(afterFare['customerFinalAmount']) ??
        d(cust['finalAmount']) ??
        d(afterFare['finalAmount']);
    final double? completed = afterFinal ?? d(trip['tripCompletedFinalAmount']) ?? d(trip['tripCompletedTotalAmount']);

    updateTripDetails(
      TripDetailsModel(
        bookingId: bookingId,
        pickupLocation: trip['pickupAddress']?.toString(),
        destinationLocation: trip['dropoffAddress']?.toString(),
        finalAmount: afterFinal,
        customerFinalAmount: afterFinal,
        tripCompletedFinalAmount: completed,
        totalFare: completed ?? afterFinal,
        distanceInKm:
            d(afterFare['distance']) ??
            d(after['distance']) ??
            d(trip['tripCompletedDistance']) ??
            d(trip['distanceKm']) ??
            d(trip['distance']),
        tripCompletedDistance: d(trip['tripCompletedDistance']),
        pricePerKm: d(afterFare['pricePerKm']) ?? d(trip['pricePerKm']),
        duration: _completedDuration(trip),
        estimatedFare: d(cust['estimatedFare']),
        serviceTax: d(cust['serviceTax']),
        tollAmount: d(cust['tollAmount']) ?? d(afterFare['tollAmount']),
        tipsAmount: d(cust['tipsAmount']),
        permitCharges: d(cust['permitCharges']),
        discountAmount: d(cust['discountAmount']),
        driverAllowance: d(cust['driverAllowance']),
        totalDriverCharges: d(cust['totalDriverCharges']),
        totalExtraCharges: d(cust['totalExtraCharges']),
        advanceAmount: d(cust['advanceAmount']) ?? d(trip['advanceAmount']),
        paymentStatus: trip['paymentStatus']?.toString(),
        paymentMethod: trip['paymentMethod']?.toString(),
      ),
      bookingId: bookingId,
    );
  }

  void setLocations({required String pickup, required String destination, String? bookingId}) {
    final p = (pickup.isEmpty || pickup == 'Locating...') ? null : pickup;
    final d = (destination.isEmpty || destination == 'Where to?') ? null : destination;
    updateTripDetails(
      TripDetailsModel(pickupLocation: p, destinationLocation: d),
      bookingId: bookingId,
    );
  }

  void setDistanceAndDuration({required double distance, required String duration, String? bookingId}) {
    updateTripDetails(
      TripDetailsModel(distanceInKm: distance, duration: duration),
      bookingId: bookingId,
    );
  }

  void setDriverDetails({
    required String name,
    required double rating,
    required String trips,
    required String? arrivalTime,
    required String plateNumber,
    required String pinCode,
    required String phone,
    required String image,
    required String destination,
    required String distanceLeft,
    required String vehicleType,
    String? bookingId,
  }) {
    updateTripDetails(
      TripDetailsModel(
        driverName: name,
        driverRating: rating,
        driverTrips: trips,
        arrivalTime: arrivalTime,
        plateNumber: plateNumber,
        startOtp: pinCode,
        driverPhone: phone,
        driverImage: image,
        destinationLocation: destination,
        distanceLeft: distanceLeft,
        vehicleType: vehicleType,
      ),
      bookingId: bookingId,
    );
  }

  void setBookingDetails({
    required String bookingId,
    required String status,
    required String pickup,
    required String drop,
    required DateTime pickupDateTime,
    DateTime? dropDateTime,
    required String vehicleType,
    String? vehicleModel,
    required double distance,
    required String duration,
    required double finalAmount,
    double? customerFinalAmount,
    double? tripCompletedFinalAmount,
    required String paymentMethod,
    required String paymentStatus,
    double? estimatedFare,
    double? pricePerKm,
    double? serviceTax,
    double? tollAmount,
    double? permitCharges,
    double? discountAmount,
    double? driverAllowance,
    double? totalDriverCharges,
    double? totalExtraCharges,
    String? driverName,
    String? driverPhone,
    String? driverImage,
    double? driverRating,
    String? driverTrips,
    String? plateNumber,
    String? startOtp,
    double? advanceAmount,
    String? endOtp,
    Map<String, dynamic>? extraCharges,
    String? passengerName,
    String? passengerPhone,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    List<Map<String, dynamic>>? stops,
    bool? isRoundTrip,
    bool markFindingDriver = true,
  }) {
    selectedBookingId.value = bookingId;
    final int? knownLeg = activeTrips[bookingId]?.currentLeg;
    updateTripDetails(
      TripDetailsModel(
        stops: stops,
        isRoundTrip: isRoundTrip,
        currentLeg: isRoundTrip == true ? (knownLeg ?? 1) : null,
        originalPickupAddress: isRoundTrip == true ? pickup : null,
        originalPickupLat: isRoundTrip == true ? pickupLat : null,
        originalPickupLng: isRoundTrip == true ? pickupLng : null,
        bookingId: bookingId,
        status: status,
        pickupLocation: pickup,
        destinationLocation: drop,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
        pickupDateTime: pickupDateTime,
        dropDateTime: dropDateTime,
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        plateNumber: plateNumber,
        distanceInKm: distance,
        duration: duration,
        finalAmount: finalAmount,
        customerFinalAmount: customerFinalAmount,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        tripCompletedFinalAmount: tripCompletedFinalAmount,
        driverName: driverName,
        driverPhone: driverPhone,
        driverImage: driverImage,
        driverRating: driverRating,
        driverTrips: driverTrips,
        startOtp: startOtp,
        totalFare: finalAmount,
        estimatedFare: estimatedFare,
        pricePerKm: pricePerKm,
        serviceTax: serviceTax,
        tollAmount: tollAmount,
        permitCharges: permitCharges,
        discountAmount: discountAmount,
        driverAllowance: driverAllowance,
        totalDriverCharges: totalDriverCharges,
        totalExtraCharges: totalExtraCharges,
        advanceAmount: advanceAmount,
        endOtp: endOtp,
        extraCharges: extraCharges,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
      ),
      bookingId: bookingId,
    );

    if (markFindingDriver && !activeStages.containsKey(bookingId)) {
      activeStages[bookingId] = RideStage.findingDriver;
    }
    ensureSocketConnectionAndListeners();
  }

  void setDates({DateTime? pickup, DateTime? drop, String? bookingId}) {
    updateTripDetails(
      TripDetailsModel(pickupDateTime: pickup, dropDateTime: drop),
      bookingId: bookingId,
    );
  }

  void clearTripDetails() {
    if (selectedBookingId.value.isNotEmpty) {
      removeTrip(selectedBookingId.value);
    }
  }

  void _clearAwaitingCash() {
    if (!Get.isRegistered<PaymentController>()) return;
    Get.find<PaymentController>().awaitingCash.value = false;
  }

  static bool isPaidStatus(String? status) {
    final v = status?.toLowerCase();
    return v == 'paid' || v == 'success';
  }

  String? _resolveTripKey(String? id) {
    if (id != null && id.isNotEmpty) {
      if (activeTrips.containsKey(id)) return id;
      for (final entry in activeTrips.entries) {
        if (entry.value.bookingId == id) return entry.key;
      }
    }
    if (activeTrips.length == 1) return activeTrips.keys.first;
    if (activeTrips.isEmpty && selectedBookingId.value.isNotEmpty) return selectedBookingId.value;
    return null;
  }

  static String? paymentMethodLabel(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    switch (v.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Wallet';
      case 'upi':
      case 'online':
      case 'razorpay':
      case 'card':
        return 'Online';
      default:
        return v;
    }
  }

  static String? _methodFrom(dynamic data) {
    if (data is! Map) return null;
    return paymentMethodLabel(
      (data['paymentMethod'] ?? data['payment_method'] ?? data['paymentMode'] ?? data['method'])?.toString(),
    );
  }

  void _seedPaymentReceipt(String id, double? amount, String? method) {
    final t = activeTrips[id];
    final String bookingId = t?.bookingId ?? id;
    if (lastPaymentBookingId != bookingId) lastPaidAmount = 0;
    socketPaymentMethod = method ?? paymentMethodLabel(t?.paymentMethod);
    lastPaymentBookingId = bookingId;
    if (lastPaidAmount <= 0) {
      lastPaidAmount = amount ?? t?.customerFinalAmount ?? t?.tripCompletedFinalAmount ?? t?.totalFare ?? 0;
    }
    lastPaymentDate = DateTime.now();
  }

  void _settlePaidTrip(String? bookingId, {bool showReceipt = false, double? paidAmount, String? paidMethod}) {
    final String? id = _resolveTripKey(bookingId);
    if (id == null || id.isEmpty) return;

    final bool wasSelected = selectedBookingId.value == id;
    if (!wasSelected && !activeTrips.containsKey(id)) return;

    if (isRoundTripFor(id) && legFor(id) < 2 && activeStages[id] == RideStage.tripInProgress) {
      return;
    }

    final bool alreadySettled = Get.currentRoute == AppRoutes.paymentSuccess || Get.currentRoute == AppRoutes.rateTrip;
    final bool receipt = showReceipt && wasSelected && !alreadySettled;
    if (receipt) _seedPaymentReceipt(id, paidAmount, paidMethod);
    suppressAutoNavFor(const Duration(milliseconds: 400));
    try {
      clearTripIfPaid(id, paymentStatus: 'paid');
      if (Get.isRegistered<ActiveTripsController>()) {
        Get.find<ActiveTripsController>().markPaid(id);
      }
      if (wasSelected && !alreadySettled) {
        Get.offAllNamed(receipt ? AppRoutes.paymentSuccess : AppRoutes.rateTrip);
      }
    } catch (_) {}
  }

  Timer? _suppressAutoNavTimer;

  void suppressAutoNavFor(Duration window) {
    suppressAutoNav = true;
    _suppressAutoNavTimer?.cancel();
    _suppressAutoNavTimer = Timer(window, () {
      suppressAutoNav = false;
    });
  }

  void releaseAutoNav() {
    _suppressAutoNavTimer?.cancel();
    _suppressAutoNavTimer = null;
    suppressAutoNav = false;
  }

  void clearTripIfPaid(String bookingId, {String? paymentStatus}) {
    if (bookingId.isEmpty) return;
    final ps = paymentStatus ?? activeTrips[bookingId]?.paymentStatus;
    if (activeTrips.containsKey(bookingId) && paymentStatus != null) {
      activeTrips[bookingId] = activeTrips[bookingId]!.copyWith(paymentStatus: paymentStatus);
    }
    if (isPaidStatus(ps)) {
      if (activeTrips.containsKey(bookingId)) {
        lastFinishedTrip = activeTrips[bookingId];
        _savePendingRating(activeTrips[bookingId]!);
      }
      removeTrip(bookingId);
    }
  }

  void removeTrip(String bookingId) {
    activeTrips.remove(bookingId);
    activeStages.remove(bookingId);
    if (selectedBookingId.value == bookingId) {
      final String next = _mostAdvancedTripId();
      selectedBookingId.value = next;
    }
  }

  String _mostAdvancedTripId() {
    if (activeTrips.isEmpty) return '';
    final ids = activeTrips.keys.toList()
      ..sort(
        (a, b) => stageRank(activeStages[b] ?? RideStage.none).compareTo(stageRank(activeStages[a] ?? RideStage.none)),
      );
    return ids.first;
  }

  void resetToDummy() {
    activeTrips.clear();
    activeStages.clear();
    selectedBookingId.value = '';
  }

  bool _isCompletedUnpaid(String id) {
    final t = activeTrips[id];
    if (t == null) return false;
    if (isPaidStatus(t.paymentStatus)) return false;
    final stage = activeStages[id];
    final completedStage = stage == RideStage.tripCompleted || stage == RideStage.payment;
    final completedStatus = (t.status?.toLowerCase() == 'completed');
    return completedStage || completedStatus;
  }

  List<String> get pendingPaymentTripIds => activeTrips.keys.where(_isCompletedUnpaid).toList();

  bool get hasPendingPaymentTrip => pendingPaymentTripIds.isNotEmpty;

  List<Map<String, dynamic>> pendingPaymentTripsAsMaps() {
    return pendingPaymentTripIds.map((id) {
      final t = activeTrips[id]!;
      return <String, dynamic>{
        '_id': id,
        'bookingId': id,
        'status': 'completed',
        'pickupAddress': t.pickupLocation ?? '',
        'dropoffAddress': t.destinationLocation ?? '',
        'paymentStatus': t.paymentStatus ?? 'pending',
        '_localPending': true,
      };
    }).toList();
  }

  void clearExceptPendingPayment() {
    final keep = pendingPaymentTripIds.toSet();
    if (keep.isEmpty) {
      resetToDummy();
      return;
    }
    activeTrips.removeWhere((id, _) => !keep.contains(id));
    activeStages.removeWhere((id, _) => !keep.contains(id));
    if (!keep.contains(selectedBookingId.value)) {
      selectedBookingId.value = _mostAdvancedTripId();
    }
  }

  bool get hasActiveTrip => activeTrips.isNotEmpty;

  bool get _serverHasOngoingTrip {
    if (!Get.isRegistered<ActiveTripsController>()) return true;
    final ctrl = Get.find<ActiveTripsController>();
    if (!ctrl.hasFetchedOngoing) return true;
    final bool has = ctrl.activeTrips.isNotEmpty || ctrl.completedUnpaidTrips.isNotEmpty;
    return has;
  }

  void updateRideStage(RideStage stage, {String? bookingId, bool legChanged = false}) {
    final targetId = bookingId ?? selectedBookingId.value;
    if (targetId.isEmpty) return;

    if (stage == RideStage.tripVerification) {
      driverArrivedAt.putIfAbsent(targetId, () => DateTime.now());
    }

    if (activeStages[targetId] == stage) {
      if (stage == RideStage.tripCancelled) removeTrip(targetId);
      if (legChanged) activeStages.refresh();
      return;
    }
    final current = activeStages[targetId] ?? RideStage.none;
    final bool reDispatch = stage == RideStage.findingDriver && current != RideStage.findingDriver;
    if (!reDispatch && !legChanged && stageRank(stage) < stageRank(current)) return;

    activeStages[targetId] = stage;
    trackDistanceKm.value = null;
    trackDurationMin.value = null;
    trackUpdatedAt = null;
    if ((stage == RideStage.tripVerification || stage == RideStage.tripInProgress) &&
        targetId == selectedBookingId.value &&
        Get.isRegistered<FindingDriverController>()) {
      Get.find<FindingDriverController>().prewarmTripRoute();
    }
    if (stage == RideStage.tripCancelled) {
      removeTrip(targetId);
    }
  }

  void resumeRideFlow() {
    switch (selectedStage) {
      case RideStage.findingDriver:
        Get.offNamedUntil(
          AppRoutes.findingDriver,
          (route) => route.settings.name == AppRoutes.home,
          arguments: {'source': 'ongoing'},
        );
        break;
      case RideStage.tripInProgress:
        Get.offNamedUntil(AppRoutes.tripInProgress, (route) => route.settings.name == AppRoutes.home);
        break;
      case RideStage.tripVerification:
        Get.offNamedUntil(AppRoutes.tripVerification, (route) => route.settings.name == AppRoutes.home);
        break;
      case RideStage.tripCompleted:
        Get.offNamedUntil(AppRoutes.tripFinished, (route) => route.settings.name == AppRoutes.home);
        break;
      case RideStage.tripCancelled:
        Get.offNamedUntil(AppRoutes.findingDriver, (route) => route.settings.name == AppRoutes.home);
        break;
      case RideStage.payment:
        Get.offNamedUntil(AppRoutes.paymentScreen, (route) => route.settings.name == AppRoutes.home);
        break;
      case RideStage.none:
        break;
    }
  }
}
