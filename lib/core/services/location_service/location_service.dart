import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';

class LocationService {
  final Dio _dio = Dio(
    BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 12)),
  );

  static const LatLng defaultLocation = LatLng(11.0168, 76.9558);
  static final RxBool permissionGranted = false.obs;

  static bool isDefault(LatLng point) =>
      point.latitude == defaultLocation.latitude && point.longitude == defaultLocation.longitude;

  static bool _granted(LocationPermission p) =>
      p == LocationPermission.whileInUse || p == LocationPermission.always;

  static Future<bool> hasPermission() async {
    try {
      final bool granted = _granted(await Geolocator.checkPermission());
      permissionGranted.value = granted;
      return granted && await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> ensurePermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      permissionGranted.value = _granted(permission);

      if (permission == LocationPermission.deniedForever) {
        AppSnackbar.error('Location Permission', 'Allow location for Orange Taxi in Settings to use your position.');
        await Geolocator.openAppSettings();
        return false;
      }
      if (!permissionGranted.value) {
        AppSnackbar.error('Location Permission', 'Location permission is needed to use your current position.');
        return false;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        AppSnackbar.error('Location Disabled', 'Turn on location services to use your current position.');
        await Geolocator.openLocationSettings();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _mapKey;
  static Future<String>? _mapKeyRequest;
  static DateTime? _mapKeyFailedAt;
  static const Duration _mapKeyRetryWindow = Duration(seconds: 30);
  static const Duration _mapKeyTimeout = Duration(seconds: 5);

  static Future<String> mapKey() async {
    if (_mapKey != null) return _mapKey!;

    final failedAt = _mapKeyFailedAt;
    if (failedAt != null && DateTime.now().difference(failedAt) < _mapKeyRetryWindow) {
      return AppConstants.googleMapsKey;
    }

    _mapKeyRequest ??= AuthRepository()
        .getConfigValue('mapApiKey')
        .timeout(_mapKeyTimeout)
        .then((value) {
          final remote = value?.trim() ?? '';
          if (remote.isNotEmpty) {
            _mapKey = remote;
            _mapKeyFailedAt = null;
            return remote;
          }
          _mapKeyRequest = null;
          _mapKeyFailedAt = DateTime.now();
          return AppConstants.googleMapsKey;
        })
        .catchError((e) {
          _mapKeyRequest = null;
          _mapKeyFailedAt = DateTime.now();
          return AppConstants.googleMapsKey;
        });

    return _mapKeyRequest!;
  }

  static String _keyTag(String key) => key.length > 8 ? '${key.substring(0, 8)}…(${key.length})' : 'empty';

  Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    try {
      final response = await Get.find<ApiService>().post(AppEndpoints.searchMaps(input), data: const {});
      if (response.statusCode == 200) {
        final list = (response.data['data'] as List?) ?? const [];
        return list.map((p) => PlacePrediction.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getNearbyPlaces(double lat, double lng, {int radius = 5000}) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
      final qp = {'location': '$lat,$lng', 'radius': '$radius', 'key': await mapKey(), 'language': 'en'};
      final response = await _dio.get(url, queryParameters: qp);
      if (response.statusCode == 200) {
        final results = (response.data['results'] as List?) ?? [];
        return results
            .map<Map<String, dynamic>>((r) {
              final loc = r['geometry']?['location'] ?? {};
              return {
                'placeId': r['place_id'] ?? '',
                'mainText': r['name'] ?? '',
                'secondaryText': r['vicinity'] ?? '',
                'lat': (loc['lat'] ?? 0.0).toDouble(),
                'lng': (loc['lng'] ?? 0.0).toDouble(),
              };
            })
            .where((e) => (e['mainText'] as String).isNotEmpty)
            .take(10)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json';
      final qp = {'place_id': placeId, 'key': await mapKey(), 'fields': 'formatted_address,geometry,name'};
      final response = await _dio.get(url, queryParameters: qp);

      if (response.statusCode == 200) {
        final result = response.data['result'];
        final status = response.data['status'];
        if (status != null && status != 'OK') {}
        if (result != null) {
          return PlaceDetails.fromJson(result);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    List<LatLng> waypoints = const [],
  }) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final key = await mapKey();
      final qp = {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'key': key,
        'mode': 'driving',
        if (waypoints.isNotEmpty) 'waypoints': waypoints.map((w) => '${w.latitude},${w.longitude}').join('|'),
      };

      final response = await _dio.get(url, queryParameters: qp);
      if (response.statusCode == 200) {
        final status = response.data['status']?.toString();
        if (status != null && status != 'OK') {
          print('[directions] status=$status key=${_keyTag(key)} error=${response.data['error_message']}');
        }
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json';
      final qp = {'latlng': '$lat,$lng', 'key': await mapKey()};

      final response = await _dio.get(url, queryParameters: qp);
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        if (results.isNotEmpty) {
          return results[0]['formatted_address'];
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>> getGeoDetails(double lat, double lng) async {
    final result = {'country': '', 'state': '', 'city': ''};
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json';
      final response = await _dio.get(url, queryParameters: {'latlng': '$lat,$lng', 'key': await mapKey()});
      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          for (final comp in (results[0]['address_components'] as List? ?? [])) {
            final types = (comp['types'] as List?)?.cast<String>() ?? const [];
            final name = (comp['long_name'] ?? '').toString();
            if (types.contains('country')) result['country'] = name;
            if (types.contains('administrative_area_level_1')) result['state'] = name;
            if (types.contains('locality')) {
              result['city'] = name;
            } else if (result['city']!.isEmpty && types.contains('administrative_area_level_2')) {
              result['city'] = name;
            }
          }
        }
      }
    } catch (_) {}
    return result;
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({required this.name, required this.formattedAddress, required this.latitude, required this.longitude});

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: (location['lat'] ?? 0.0).toDouble(),
      longitude: (location['lng'] ?? 0.0).toDouble(),
    );
  }
}
