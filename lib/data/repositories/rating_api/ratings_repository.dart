import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/settings/models/rating_model.dart';

class RatingsRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<RatingModel>> getRatings() async {
    try {
      final response = await _apiService.get(AppEndpoints.ratings, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = (response.data['data']?['ratings'] as List?) ?? const [];
        return list.whereType<Map>().map((e) => RatingModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load ratings');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
