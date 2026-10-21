import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/model/saved_address_model.dart';
import 'package:orange_taxi_customer_app/core/services/location_service/location_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationSearchController extends GetxController {
  HomeController get homeController => Get.find<HomeController>();
  final LocationService _locationService = LocationService();

  final TextEditingController searchController = TextEditingController();

  RxList<Map<String, dynamic>> recentSearches = <Map<String, dynamic>>[].obs;

  List<AddressModel> get savedAddresses {
    if (!Get.isRegistered<SavedAddressesController>()) return const [];
    return Get.find<SavedAddressesController>().addresses
        .where((a) => a.isPersisted && a.latitude != null && a.longitude != null)
        .toList();
  }

  List<AddressModel> get savedSlots {
    if (!Get.isRegistered<SavedAddressesController>()) return const [];
    return Get.find<SavedAddressesController>().addresses.toList();
  }

  RxList<Map<String, dynamic>> suggestions = <Map<String, dynamic>>[].obs;

  RxList<Map<String, dynamic>> popularNearby = <Map<String, dynamic>>[].obs;

  static const List<Map<String, dynamic>> _popularDestinations = [
    {'mainText': 'Gandhipuram', 'secondaryText': 'Coimbatore', 'lat': 11.0176, 'lng': 76.9674},
    {'mainText': 'Prozone Mall', 'secondaryText': 'Saravanampatti, Coimbatore', 'lat': 11.0857, 'lng': 77.0000},
    {'mainText': 'Brookefields Mall', 'secondaryText': 'Coimbatore', 'lat': 11.0027, 'lng': 76.9662},
    {'mainText': 'KMCH Hospital', 'secondaryText': 'Avinashi Road, Coimbatore', 'lat': 11.0517, 'lng': 77.0478},
    {'mainText': 'SITRA', 'secondaryText': 'Avinashi Road, Coimbatore', 'lat': 11.0287, 'lng': 77.0407},
    {'mainText': 'Coimbatore Junction Railway Station', 'secondaryText': 'Coimbatore', 'lat': 10.9990, 'lng': 76.9660},
    {'mainText': 'Coimbatore International Airport', 'secondaryText': 'Coimbatore', 'lat': 11.0299, 'lng': 77.0434},
  ];

  RxBool isLoading = false.obs;

  RxBool showAllSaved = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();

    if (Get.isRegistered<SavedAddressesController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<SavedAddressesController>()) {
          Get.find<SavedAddressesController>().loadSavedAddresses();
        }
      });
    } else {
      Get.put(SavedAddressesController(), permanent: true);
    }
    popularNearby.assignAll(_popularDestinations);
    searchController.addListener(_onSearchChanged);
    _prefillFromPrevious();
  }

  void _prefillFromPrevious() {
    final arg = Get.arguments;
    String? seed;
    if (arg == 'Pickup') {
      final v = homeController.pickupAddress.value;
      if (v.isNotEmpty && v != 'Locating...') seed = v;
    } else if (arg == 'Destination') {
      final v = homeController.destinationAddress.value;
      if (v.isNotEmpty && v != 'Where to?') seed = v;
    }
    if (seed == null) return;
    searchController.text = seed;
    searchController.selection = TextSelection.collapsed(offset: seed.length);
  }

  Future<void> _loadRecentSearches() async {
    final searches = await LocalStorageService.getRecentSearches();
    recentSearches.assignAll(searches);

    if (searchController.text.trim().isEmpty) {
      final saved = await LocalStorageService.getSavedAddresses();
      final List<Map<String, dynamic>> combined = [];

      saved.forEach((key, value) {
        combined.add({...value, 'type': 'saved', 'label': key});
      });
      combined.addAll(recentSearches.map((e) => {...e, 'type': 'recent'}));

      suggestions.assignAll(combined);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(searchController.text);
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.trim().isEmpty) {
      await _loadRecentSearches();
      return;
    }

    try {
      isLoading.value = true;
      final results = await _locationService.getPlacePredictions(input);

      suggestions.assignAll(
        results
            .map(
              (p) => {
                'placeId': p.placeId,
                'mainText': p.mainText,
                'secondaryText': p.secondaryText,
                'description': p.description,
              },
            )
            .toList(),
      );
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  static const Set<String> _resultModes = {'PickAddress', 'SavedAddress', 'Stop', 'EditPickup', 'EditDestination'};

  bool get _returnsResult => _resultModes.contains(Get.arguments);

  Future<void> selectLocation(Map<String, dynamic> suggestion) async {
    try {
      isLoading.value = true;

      final String mainText = suggestion['mainText'].toString();
      final String secondaryText = (suggestion['secondaryText'] ?? '').toString();

      final bool alreadyResolved = suggestion.containsKey('lat') && suggestion.containsKey('lng');
      final String fullAddress = alreadyResolved
          ? mainText
          : (suggestion['description']?.toString().isNotEmpty ?? false)
          ? suggestion['description'].toString()
          : (secondaryText.isNotEmpty ? '$mainText, $secondaryText' : mainText);
      LatLng? latLng;

      if (suggestion.containsKey('lat') && suggestion.containsKey('lng')) {
        latLng = LatLng(suggestion['lat'] as double, suggestion['lng'] as double);
      } else {
        final placeId = suggestion['placeId'].toString();
        final details = await _locationService.getPlaceDetails(placeId);
        if (details != null) {
          latLng = LatLng(details.latitude, details.longitude);
        }
      }

      if (latLng != null) {
        final searchData = {
          'placeId': suggestion['placeId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'mainText': fullAddress,
          'secondaryText': secondaryText,
          'lat': latLng.latitude,
          'lng': latLng.longitude,
        };

        if (_returnsResult) {
          await LocalStorageService.saveRecentSearch(searchData);
          Get.back(result: searchData);
          return;
        }

        final bool targetIsPickup = homeController.isSelectingPickup.value;
        if (homeController.editingSavedAddressType == null &&
            homeController.rejectIfDuplicate(latLng, skipPickup: targetIsPickup, skipDestination: !targetIsPickup)) {
          return;
        }

        await homeController.moveToLocation(latLng, fullAddress, searchData: searchData);
        if (!homeController.isRoutingToSummary) Get.back();
      } else {
        AppSnackbar.error("Error", "Could not get location details");
      }
    } catch (e) {
      debugPrint(e.toString());
      AppSnackbar.error("Error", "Could not select location");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearRecent() async {
    await LocalStorageService.clearRecentSearches();
    recentSearches.clear();
    await _loadRecentSearches();
  }

  Future<void> removeRecent(Map<String, dynamic> search) async {
    await LocalStorageService.removeRecentSearch(search);
    await _loadRecentSearches();
  }

  Future<void> useCurrentLocation() async {
    try {
      isLoading.value = true;

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      final address = await _locationService.getAddressFromLatLng(latLng.latitude, latLng.longitude);

      if (address != null) {
        if (_returnsResult) {
          Get.back(
            result: {
              'placeId': DateTime.now().millisecondsSinceEpoch.toString(),
              'mainText': address,
              'secondaryText': '',
              'lat': latLng.latitude,
              'lng': latLng.longitude,
            },
          );
          return;
        }

        await homeController.moveToLocation(latLng, address);
        if (!homeController.isRoutingToSummary) Get.back();
      } else {
        AppSnackbar.error("Error", "Could not get current address");
      }
    } catch (e) {
      debugPrint("Error using current location: $e");
      AppSnackbar.error("Error", "Could not get current location");
    } finally {
      isLoading.value = false;
    }
  }
}
