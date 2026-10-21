import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';

class ProfileRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(AppEndpoints.customerProfile);
      if (response.statusCode == 200 && response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to load profile');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
Future<Map<String, dynamic>> updateProfilePicture(String url) async {
    try {
      final response = await _apiService.patch(AppEndpoints.customerProfile, data: {"profileImageUrl": url});
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to update profile');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    try {
      final response = await _apiService.patch(AppEndpoints.customerProfile, data: body);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to update profile');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _apiService.delete(AppEndpoints.customerProfile);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data ?? {});
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to delete account');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
