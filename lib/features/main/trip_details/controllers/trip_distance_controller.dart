import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/core/services/location_service/location_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class TripDistanceController extends GetxController {
  final RxnDouble distanceKm = RxnDouble();
  final RxnInt etaMinutes = RxnInt();

  final TripStateService _tripState = Get.find<TripStateService>();
  final LocationService _locationService = LocationService();

  static const Duration _minInterval = Duration(seconds: 15);
  static const double _minMoveMetres = 150;

  StreamSubscription<Position>? _posSub;
  LatLng? _currentPosition;
  LatLng? _lastFetchOrigin;
  LatLng? _lastFetchDestination;
  DateTime? _lastFetchAt;
  bool _fetching = false;

  @override
  void onInit() {
    super.onInit();
    _startLocationUpdates();
    ever(_tripState.activeTrips, (_) => refresh());
  }

  @override
  void onClose() {
    _posSub?.cancel();
    super.onClose();
  }

  Future<void> _startLocationUpdates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final Position first = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      _currentPosition = LatLng(first.latitude, first.longitude);
      refresh(force: true);
    } catch (_) {}

    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
        ).listen((pos) {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          refresh();
        }, onError: (_) {});
  }

  LatLng? get _destination => _tripState.activeDestinationFor(null);

  bool _shouldFetch(LatLng origin, LatLng destination, bool force) {
    if (force || _lastFetchAt == null) return true;

    final LatLng? lastDest = _lastFetchDestination;
    if (lastDest == null || lastDest.latitude != destination.latitude || lastDest.longitude != destination.longitude) {
      return true;
    }

    if (DateTime.now().difference(_lastFetchAt!) < _minInterval) return false;

    final LatLng? lastOrigin = _lastFetchOrigin;
    if (lastOrigin == null) return true;

    final double moved = Geolocator.distanceBetween(
      lastOrigin.latitude,
      lastOrigin.longitude,
      origin.latitude,
      origin.longitude,
    );
    return moved >= _minMoveMetres;
  }

  Future<void> refresh({bool force = false}) async {
    if (_fetching) return;

    final LatLng? origin = _currentPosition;
    final LatLng? destination = _destination;
    if (origin == null || destination == null) return;
    if (!_shouldFetch(origin, destination, force)) return;

    _fetching = true;
    try {
      final data = await _locationService.getDirections(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );

      if (data == null || data['status'] != 'OK') return;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;

      final legs = (routes.first as Map)['legs'] as List?;
      if (legs == null || legs.isEmpty) return;

      double metres = 0;
      double seconds = 0;
      for (final leg in legs) {
        metres += ((leg as Map)['distance']?['value'] as num?)?.toDouble() ?? 0;
        seconds += (leg['duration']?['value'] as num?)?.toDouble() ?? 0;
      }
      if (metres <= 0) return;

      distanceKm.value = metres / 1000;
      etaMinutes.value = (seconds / 60).round();

      _lastFetchAt = DateTime.now();
      _lastFetchOrigin = origin;
      _lastFetchDestination = destination;
    } catch (_) {
    } finally {
      _fetching = false;
    }
  }
}
