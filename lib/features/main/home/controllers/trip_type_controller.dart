import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';

enum TripType { oneWay, roundTrip, airportTransfer }

class TripController extends GetxController {
  final ApiService _apiService = ApiService();

  var selectedType = TripType.oneWay.obs;
  final tripData = <TripType, Map<String, dynamic>>{}.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCachedTripTypes();
    getTripTypes();

    if (Get.isRegistered<ConnectivityService>()) {
      ever(Get.find<ConnectivityService>().isReachable, (bool reachable) {
        if (reachable) getTripTypes();
      });
    }
  }

  Future<void> _loadCachedTripTypes() async {
    final cached = await LocalStorageService.getServiceTypes();
    if (cached.isEmpty || tripData.isNotEmpty) return;
    setTripTypes(cached);
  }

  Future<void> getTripTypes() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await _apiService.get(AppEndpoints.services, requiresToken: true);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          setTripTypes(data);
          LocalStorageService.saveServiceTypes(data);
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> ensureServiceTypes() async {
    if (serviceId.isNotEmpty) return true;
    await getTripTypes();
    return serviceId.isNotEmpty;
  }

  void setTripType(TripType type) {
    if (selectedType.value == type) return;
    selectedType.value = type;
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().resetTripSelection();
    }
  }

  void setTripTypes(List data) {
    for (var item in data) {
      final type = _mapNameToEnum(item['name']?.toString() ?? '');

      if (type != null) {
        tripData[type] = Map<String, dynamic>.from(item as Map);
      }
    }
    tripData.refresh();
  }

  TripType? _mapNameToEnum(String name) {
    switch (name.toLowerCase()) {
      case 'one way':
        return TripType.oneWay;

      case 'round trip':
        return TripType.roundTrip;

      case 'airport transfer':
        return TripType.airportTransfer;

      default:
        return null;
    }
  }

  String get typeLabel {
    return tripData[selectedType.value]?['name'] ?? '';
  }

  String get serviceId {
    return tripData[selectedType.value]?['serviceId'] ?? '';
  }

  List<String> get allowedBookingTypes {
    return List<String>.from(tripData[selectedType.value]?['allowedBookingTypes'] ?? []);
  }

  List<String> get airportCities {
    return List<String>.from(tripData[TripType.airportTransfer]?['cities'] ?? []);
  }

  String get serviceType {
    return tripData[selectedType.value]?['name'] ?? '';
  }
}
