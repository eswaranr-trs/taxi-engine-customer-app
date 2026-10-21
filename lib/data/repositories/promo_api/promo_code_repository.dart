import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/offers/models/promo_code_model.dart';

class PromoCodeRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<PromoCodeModel>> getEligiblePromoCodes() async {
    try {
      final response = await _apiService.get(AppEndpoints.promoCodesEligible, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = (response.data['data']?['promoCodes'] as List?) ?? const [];
        return list
            .whereType<Map>()
            .map((e) => PromoCodeModel.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => p.code.isNotEmpty)
            .toList();
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load promo codes');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
