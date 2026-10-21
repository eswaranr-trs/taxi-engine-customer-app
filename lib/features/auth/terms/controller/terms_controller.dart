import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';

class TermsController extends GetxController {
  var isTermsAccepted = false.obs;
  var isPrivacyAccepted = false.obs;
  var isLoading = false.obs;

  bool get canContinue => isTermsAccepted.value && isPrivacyAccepted.value;

  void toggleTerms(bool? value) {
    if (value != null) isTermsAccepted.value = value;
  }

  void togglePrivacy(bool? value) {
    if (value != null) isPrivacyAccepted.value = value;
  }

  Future<void> submitConsent() async {
    if (!canContinue) return;

    isLoading.value = true;
    try {
      String ipAddress = 'unknown';
      try {
        final response = await Dio().get('https://api.ipify.org?format=json');
        if (response.statusCode == 200) {
          ipAddress = response.data['ip'];
        }
      } catch (e) {
        print('Failed to get IP address: $e');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      const policyVersion = 'v1.0';

      await LocalStorageService.saveConsentData(ipAddress, timestamp, policyVersion);

      await Get.offAllNamed(AppRoutes.signup);
    } catch (e) {
      AppSnackbar.error('Error', 'Failed to save consent. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
