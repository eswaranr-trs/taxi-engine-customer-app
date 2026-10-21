import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import '../../../core/services/network_service/api_service.dart';
import '../../../config/constants/app_endpoints.dart';

class EnquiryRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<Map<String, dynamic>?> getEstimation({
    required final String pickUp,
    required final String drop,
    required final List<Map<String, dynamic>> stops,
    final String? pickupDate,
    final String? dropDate,
    required final String serviceTypeId,
    required final double pickupLat,
    required final double pickupLng,
    required final double dropLat,
    required final double dropLng,
    final String? offerId,
    final bool isOfferApply = false,
  }) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.getEstimation,
        data: {
          "pickup": {"address": pickUp, "lat": pickupLat, "lng": pickupLng},
          "stops": stops,
          "dropoff": {"address": drop, "lat": dropLat, "lng": dropLng},
          "service_type_id": serviceTypeId,
          if (pickupDate != null && pickupDate.isNotEmpty) "pickupDate": pickupDate,
          if (dropDate != null && dropDate.isNotEmpty) "dropDate": dropDate,
          if (isOfferApply && (offerId?.isNotEmpty ?? false)) ...{"offerId": offerId, "isOfferApply": true},
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(message: response.data['message'] ?? 'Failed to get estimation', data: response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Failed to get estimation');
    }
  }

  Future<Map<String, dynamic>?> createBooking(final Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(AppEndpoints.createBooking, data: data);

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to create booking',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Failed to create booking');
    } catch (e) {
      if (e is ApiException) throw ApiException(message: e.toString());
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> cancelTrip({required final String tripId, String reason = 'Booked by mistake'}) async {
    try {
      final response = await _apiService.post(AppEndpoints.cancelTrip(tripId), data: {'reason': reason.trim()});

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message']?.toString() ?? 'Failed to cancel trip',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Failed to cancel trip');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}
