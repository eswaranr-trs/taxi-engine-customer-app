import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class AppConfirmDialog {
  static Future<bool> show({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    Color accent = AppColors.red,
  }) async {
    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 28),
              ),
              20.height,
              CustomText(
                text: title,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                textAlign: TextAlign.center,
              ),
              12.height,
              CustomText(text: message, fontSize: 14, color: AppColors.grey500, textAlign: TextAlign.center),
              24.height,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.grey200),
                        ),
                      ),
                      onPressed: () => Get.back(result: false),
                      child: CustomText(
                        text: cancelText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Get.back(result: true),
                      child: CustomText(
                        text: confirmText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }
}
