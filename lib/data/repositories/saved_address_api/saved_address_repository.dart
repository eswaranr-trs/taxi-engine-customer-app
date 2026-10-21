import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';

class SavedAddressRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<Map<String, dynamic>>> getAddresses() async {
    try {
      final response = await _apiService.get(AppEndpoints.savedAddresses);
      if (response.statusCode == 200) {
        final data = response.data;
        final List raw = data is List ? data : (data['data'] ?? data['addresses'] ?? []);
        return raw.cast<Map<String, dynamic>>();
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load addresses');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(AppEndpoints.savedAddresses, data: body);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? response.data);
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to create address');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> body) async {
    try {
      final response = await _apiService.put(AppEndpoints.savedAddress(id), data: body);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? response.data);
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to update address');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final response = await _apiService.delete(AppEndpoints.savedAddress(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to delete address');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
