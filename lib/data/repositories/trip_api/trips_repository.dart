import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';

class TripsRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<Map<String, dynamic>?> getTrips(String status) async {
    try {
      late Response response;
      if (status == 'scheduled') {
        response = await _apiService.get('${AppEndpoints.scheduledTrips}$status', requiresToken: true);
      } else {
        response = await _apiService.get('${AppEndpoints.myTrips}$status', requiresToken: true);
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Failed to fetch trips',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> confirmBooking(String bookingId) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.confirmBooking(bookingId),
        data: const {},
        requiresToken: true,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data as Map<String, dynamic>?;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to confirm booking',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> createAdvancePayment(
    String bookingId, {
    required int percentage,
    required String method,
  }) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.advancePayment(bookingId),
        data: {'percentage': percentage, 'paymentMethod': method},
        requiresToken: true,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to start advance payment',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Failed to start advance payment');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<String> requestEndTrip(String bookingId) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.endTripRequest(bookingId),
        data: const {},
        requiresToken: true,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data['message']?.toString() ?? 'End trip request sent to driver successfully.';
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to request end trip',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<({String message, String? endOtp})> startReturnTrip(String bookingId) async {
    try {
      final response = await _apiService.patch(
        AppEndpoints.startReturnTrip(bookingId),
        data: const {},
        requiresToken: true,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        final Map payload = response.data['data'] is Map
            ? response.data['data'] as Map
            : (response.data['trip'] is Map ? response.data['trip'] as Map : const {});
        final String otp =
            (payload['endOtp'] ?? payload['end_otp'] ?? response.data['endOtp'] ?? response.data['end_otp'] ?? '')
                .toString()
                .trim();
        return (
          message: response.data['message']?.toString() ?? 'Return journey started.',
          endOtp: (otp.isEmpty || otp == 'null' || otp == '0') ? null : otp,
        );
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to start the return journey',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<String> tipTrip(String tripId, num amount) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.tripTip(tripId),
        data: {'amount': amount},
        requiresToken: true,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data['message']?.toString() ?? 'Tip added successfully.';
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to add tip',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> getTripById(String bookingId) async {
    try {
      final response = await _apiService.get('${AppEndpoints.trip}$bookingId', requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] is Map ? Map<String, dynamic>.from(response.data['data']) : null;
      }
      return null;
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDriverLocation(String bookingId) async {
    try {
      final response = await _apiService.get(AppEndpoints.driverLocation(bookingId));
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return null;
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNearbyDrivers(double lat, double lng) async {
    try {
      final response = await _apiService.get(AppEndpoints.nearbyDrivers(lat, lng), requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to fetch nearby drivers',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> getImmediateActiveTrips() async {
    try {
      final response = await _apiService.get(AppEndpoints.ongoingTrips, requiresToken: true);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Failed to fetch active trips',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> cancelSOS(String sosId, {String reason = 'False alarm'}) async {
    try {
      final Response response = await _apiService.patch(
        AppEndpoints.cancelSos(sosId),
        data: {'reason': reason},
        requiresToken: true,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to cancel SOS',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> tripSOS(Map<String, dynamic> data) async {
    try {
      final Response response = await _apiService.post(
        AppEndpoints.sos,
        data: {'latitude': data['latitude'], 'longitude': data['longitude'], 'bookingId': data['booking_id']},
        requiresToken: true,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Failed to call SOS',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> removeTip(String bookingId) async {
    try {
      final Response response = await _apiService.delete('${AppEndpoints.trip}$bookingId/tip', requiresToken: true);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to remove tip',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> addTip(String bookingId, num amount) async {
    try {
      final Response response = await _apiService.post(
        '${AppEndpoints.trip}$bookingId/tip',
        data: {"amount": amount},
        requiresToken: true,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Failed to add tip',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> rateTrip(Map<String, dynamic> data) async {
    try {
      final Response response = await _apiService.post(
        '${AppEndpoints.trip}${data['booking_id']}/rate',
        data: {"rating": data['rating'], "comment": data['comment']},
        requiresToken: true,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Failed to rate trip',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<List<int>> downloadInvoice(String tripId) async {
    try {
      final response = await _apiService.get(
        AppEndpoints.tripInvoiceDownload(tripId),
        responseType: ResponseType.bytes,
      );
      if (response.statusCode == 200 && response.data != null) {
        return List<int>.from(response.data);
      }
      throw ApiException(message: 'Failed to download invoice', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw ApiException(message: e.message ?? 'Network Error', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
