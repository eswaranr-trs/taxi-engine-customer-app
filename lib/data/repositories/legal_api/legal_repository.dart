import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/legal/model/legal_document.dart';
import '../../../core/services/network_service/api_service.dart';
import '../../../config/constants/app_endpoints.dart';

class LegalRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<LegalDocument> getDocument(final LegalDocType type, {final String? serviceType}) async {
    final String path = type == LegalDocType.privacyPolicy
        ? AppEndpoints.legalPrivacyPolicy
        : AppEndpoints.legalTermsAndConditions;

    try {
      final response = await _apiService.get(
        path,
        requiresToken: false,
        queryParameters: (serviceType == null || serviceType.isEmpty) ? null : {'serviceType': serviceType},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return LegalDocument.fromJson(Map<String, dynamic>.from(response.data['data']));
      }

      throw ApiException(message: response.data['message'] ?? 'Failed to load document', data: response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Failed to load document');
    }
  }
}
