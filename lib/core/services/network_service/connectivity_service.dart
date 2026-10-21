import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  final RxBool isConnected = true.obs;
  final RxBool isServerDown = false.obs;

  final RxBool isReachable = true.obs;

  void _syncReachable() {
    final bool reachable = isConnected.value && !isServerDown.value;
    if (isReachable.value == reachable) return;
    print('[connectivity] isReachable -> $reachable (online=${isConnected.value}, serverDown=${isServerDown.value})');
    isReachable.value = reachable;
  }

  int _socketUpgradeFailures = 0;
  bool _verifyingServer = false;

  Future<void> verifyServerDown() async {
    if (isServerDown.value || _verifyingServer) return;
    _verifyingServer = true;
    try {
      if (!await serverHealthy()) reportServerDown();
    } finally {
      _verifyingServer = false;
    }
  }

  void reportServerDown() {
    if (!isServerDown.value) {
      print('[connectivity] server unreachable (5xx) — showing server-down screen');
      isServerDown.value = true;
    }
  }

  void reportSocketUpgradeFailure() {
    _socketUpgradeFailures++;
    print('[connectivity] socket upgrade failed (count=$_socketUpgradeFailures)');
    if (_socketUpgradeFailures >= 2) verifyServerDown();
  }

  void reportServerUp() {
    _socketUpgradeFailures = 0;
    if (isServerDown.value) {
      print('[connectivity] server recovered — clearing server-down state');
      isServerDown.value = false;
    }
  }

  Future<bool> serverHealthy() async {
    try {
      final res = await Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          validateStatus: (_) => true,
        ),
      ).get(AppEndpoints.companyProfile);
      final int code = res.statusCode ?? 0;
      return code > 0 && code < 500;
    } catch (_) {
      return false;
    }
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<ConnectivityService> init() async {
    ever(isConnected, (_) => _syncReachable());
    ever(isServerDown, (_) => _syncReachable());
    await _checkInitialConnection();
    _syncReachable();
    _listenToConnectionChanges();
    return this;
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    isConnected.value = !results.contains(ConnectivityResult.none);
  }

  void _listenToConnectionChanges() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final connected = !results.contains(ConnectivityResult.none);
      isConnected.value = connected;
    });
  }

  Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
