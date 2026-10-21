import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/features/auth/language/controllers/language_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class LanguageScreen extends GetView<LanguageController> {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: SizedBox.shrink(),
        title: CustomText(text: 'select_language'.tr, fontWeight: FontWeight.bold),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),

        child: SizedBox(
          height: Get.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildLanguageOption(title: 'தமிழ்', code: 'ta_IN'),
                    10.height,
                    _buildLanguageOption(title: 'English', code: 'en_US'),
                    10.height,

                    // _buildLanguageOption(title: 'हिंदी', code: 'hi_IN'),
                    10.height,

                    // _buildLanguageOption(title: 'తెలుగు', code: 'te_IN'),
                    // 10.height,

                    // _buildLanguageOption(title: 'ಕನ್ನಡ', code: 'kn_IN'),
                    // 10.height,

                    // _buildLanguageOption(title: 'বাংলা', code: 'bn_IN'),
                    // 10.height,

                    // _buildLanguageOption(title: 'मराठी', code: 'mr_IN'),
                    // 10.height,

                    // _buildLanguageOption(title: 'ગુજરાતી', code: 'gu_IN'),
                    // 10.height,

                    // _buildLanguageOption(title: 'العربية', code: 'ar_AE'),
                    // 10.height,
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: controller.onContinue,

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),

                child: CustomText(
                  text: 'continue_btn'.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({required final String title, required final String code}) {
    return Obx(() {
      final bool isSelected = controller.selectedLanguage.value == code;

      return GestureDetector(
        onTap: () => controller.changeLanguage(code),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange.withValues(alpha: 0.1) : AppColors.white,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: isSelected ? AppColors.orange : AppColors.grey300, width: 2),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              CustomText(
                text: title,
                fontSize: 16,

                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,

                color: isSelected ? AppColors.orange : AppColors.black,
              ),

              if (isSelected) const Icon(Icons.check_circle, color: AppColors.orange),
            ],
          ),
        ),
      );
    });
  }
}
