import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';

class LanguageController extends GetxController {
  final selectedLanguage = 'en_US'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialLanguage();
  }

  void _loadInitialLanguage() async {
    String? lang = await LocalStorageService.getLanguage();
    if (lang != null) {
      selectedLanguage.value = lang;
    }
  }

  void changeLanguage(String localeCode) {
    selectedLanguage.value = localeCode;

    final parts = localeCode.split('_');

    final locale = Locale(parts[0], parts[1]);

    Get.updateLocale(locale);
  }

  void onContinue() async {
    await LocalStorageService.saveLanguage(selectedLanguage.value);

    bool fromSettings = Get.arguments?['fromSettings'] ?? false;

    if (fromSettings) {
      Get.back();
    } else {
      await Get.offNamed(AppRoutes.welcome);
    }

    // bool loggedIn = await LocalStorageService.isLoggedIn();

    // if (loggedIn) {
    //   await Get.offNamed(AppRoutes.welcome);
    // } else {
    //   await Get.offNamed(AppRoutes.signup);
    // }
  }
}
