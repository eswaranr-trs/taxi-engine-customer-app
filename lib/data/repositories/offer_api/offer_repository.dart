import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/offers/models/offer_model.dart';

class OfferRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<OfferModel>> getEligibleOffers(String serviceType) async {
    try {
      final response = await _apiService.get(AppEndpoints.offers, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = (response.data['data'] as List?) ?? const [];
        final offers = list.whereType<Map>().map((e) => OfferModel.fromJson(Map<String, dynamic>.from(e))).toList();
        offers.sort((a, b) => a.priority.compareTo(b.priority));
        return offers;
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load offers');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
