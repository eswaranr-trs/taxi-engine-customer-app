import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';

class UploadRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<String> uploadImage(String filePath, String fileName, {String folder = 'uploads'}) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'folder': folder,
      });
      final response = await _apiService.post(AppEndpoints.globalUpload, data: form);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data?['success'] == true) {
        final url = response.data['data']?['publicUrl']?.toString();
        if (url != null && url.isNotEmpty) return url;
        throw ApiException(message: 'Upload succeeded but no publicUrl returned');
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to upload file');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      if (e is ApiException) throw ApiException(message: e.toString());
      throw ApiException(message: e.toString());
    }
  }
}
