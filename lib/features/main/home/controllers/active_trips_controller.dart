import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';

import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';

class ActiveTripsController extends GetxController {
  final TripsRepository _tripsRepository = TripsRepository();

  RxList<Map<String, dynamic>> activeTrips = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> completedUnpaidTrips = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  bool hasFetchedOngoing = false;

  final Set<String> _paidIds = <String>{};
  bool _idMatches(Map<String, dynamic> t, String id) => (t['_id'] ?? t['bookingId'] ?? '').toString() == id;

  void markPaid(String bookingId) {
    if (bookingId.isEmpty) return;
    _paidIds.add(bookingId);
    activeTrips.removeWhere((t) => _idMatches(t, bookingId));
    completedUnpaidTrips.removeWhere((t) => _idMatches(t, bookingId));
  }

  bool _isPaidLocally(Map<String, dynamic> t) {
    final id = t['_id']?.toString() ?? '';
    final bid = t['bookingId']?.toString() ?? '';
    return _paidIds.contains(id) || _paidIds.contains(bid);
  }

  final Set<String> _cancelledIds = <String>{};

  void markCancelled(String bookingId) {
    if (bookingId.isEmpty) return;
    _cancelledIds.add(bookingId);
    activeTrips.removeWhere((t) => _idMatches(t, bookingId));
    completedUnpaidTrips.removeWhere((t) => _idMatches(t, bookingId));
  }

  bool _isCancelledLocally(Map<String, dynamic> t) {
    final id = t['_id']?.toString() ?? '';
    final bid = t['bookingId']?.toString() ?? '';
    return _cancelledIds.contains(id) || _cancelledIds.contains(bid);
  }

  List<Map<String, dynamic>> get displayTrips {
    final ts = Get.find<TripStateService>();
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    void add(Map<String, dynamic> t) {
      final id = (t['_id'] ?? t['bookingId'] ?? '').toString();
      if (id.isEmpty || seen.contains(id)) return;
      seen.add(id);
      merged.add(t);
    }

    for (final t in completedUnpaidTrips) {
      add(t);
    }
    for (final t in ts.pendingPaymentTripsAsMaps()) {
      add(t);
    }
    for (final t in activeTrips) {
      add(t);
    }

    return merged;
  }

  bool _isUnpaid(Map<String, dynamic> t) {
    final ps = t['paymentStatus']?.toString();
    return ps != null && ps.isNotEmpty && !TripStateService.isPaidStatus(ps);
  }

  @override
  void onInit() {
    super.onInit();
    fetchActiveTrips();

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) fetchActiveTrips();
      });
    }
  }

  Future<void>? _inFlight;

  Future<_FetchResult> _guarded(Future<dynamic> call, String label) async {
    try {
      return _FetchResult(true, await call);
    } catch (e) {
      debugPrint('[active-trips] $label failed: $e');
      return const _FetchResult(false, null);
    }
  }

  Future<void> fetchActiveTrips() {
    final existing = _inFlight;
    if (existing != null) {
      debugPrint('[active-trips] fetch already in flight — joining it');
      return existing;
    }
    final future = _runFetch().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<void> _runFetch() async {
    if (activeTrips.isEmpty && completedUnpaidTrips.isEmpty) isLoading.value = true;

    final results = await Future.wait([
      _guarded(_tripsRepository.getImmediateActiveTrips(), 'getImmediateActiveTrips'),
      _guarded(_tripsRepository.getTrips('completed'), 'getTrips(completed)'),
    ]);

    final _FetchResult ongoing = results[0];
    final _FetchResult completed = results[1];
    final bool reviewing = AppRoutes.tripFlowRoutes.contains(Get.currentRoute);

    if (ongoing.ok) {
      hasFetchedOngoing = true;
      final list = _extractTripList(ongoing.data).where((t) => !_isPaidLocally(t) && !_isCancelledLocally(t)).toList();
      if (list.isNotEmpty) {
        activeTrips.assignAll(list);
      } else {
        activeTrips.clear();
        if (!reviewing) Get.find<TripStateService>().clearExceptPendingPayment();
      }
    } else {
      debugPrint('[active-trips] ongoing fetch errored — keeping ${activeTrips.length} known trip(s), no state wipe');
    }

    if (completed.ok) {
      completedUnpaidTrips.assignAll(
        _extractTripList(
          completed.data,
        ).where(_isUnpaid).where((t) => !_isPaidLocally(t) && !_isCancelledLocally(t)).toList(),
      );
    } else {
      debugPrint('[active-trips] completed fetch errored — keeping ${completedUnpaidTrips.length} known trip(s)');
    }

    isLoading.value = false;
  }

  List<Map<String, dynamic>> _extractTripList(dynamic node) {
    if (node is List) {
      final maps = node.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (maps.isNotEmpty && _looksLikeTrip(maps.first)) return maps;
    }
    if (node is Map) {
      for (final key in ['data', 'trips', 'results', 'items', 'bookings']) {
        if (node.containsKey(key)) {
          final found = _extractTripList(node[key]);
          if (found.isNotEmpty) return found;
        }
      }
      for (final value in node.values) {
        final found = _extractTripList(value);
        if (found.isNotEmpty) return found;
      }
    }
    return [];
  }

  bool _looksLikeTrip(Map<String, dynamic> m) {
    const tripKeys = ['_id', 'bookingId', 'status', 'pickupAddress', 'dropoffAddress'];
    return tripKeys.any(m.containsKey);
  }
}

class _FetchResult {
  final bool ok;
  final dynamic data;

  const _FetchResult(this.ok, this.data);
}
