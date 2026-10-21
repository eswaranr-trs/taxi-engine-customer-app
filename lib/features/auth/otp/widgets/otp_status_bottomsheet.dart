import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/controller/otp_controller.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/timer.dart';
import 'package:orange_taxi_customer_app/core/services/support_service/support_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import '../../../../core/custom_widgets/custom_sizedbox/custom_sizedbox.dart' show SpaceExtension;

class OtpStatusBottomSheet extends StatelessWidget {
  final bool isSuccess;
  final String? title;
  final String? message;
  final VoidCallback? onButtonPressed;
  final String buttonText;
  final String type;
  final String? statusLabel;

  final bool isBlocked;

  OtpStatusBottomSheet({
    super.key,
    required this.isSuccess,
    this.title,
    this.message,
    this.onButtonPressed,
    this.buttonText = 'Continue',
    this.type = "",
    this.statusLabel,
    this.isBlocked = false,
  });

  final controller = Get.find<OtpController>();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          !isSuccess
              ? Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
                  ),
                )
              : const SizedBox.shrink(),
          28.height,
          isBlocked
              ? Obx(
                  () => AnimatedCountdownTimer(
                    duration: controller.actualRemainingSeconds.seconds,
                    totalDuration: controller.actualRemainingSeconds.seconds,
                    color: AppColors.primary,
                  ),
                )
              : isSuccess
              ? Image.asset('assets/images/otp_success.png', height: 150, width: 280)
              : Image.asset('assets/images/otp_failure.png', height: 150, width: 300),
          CustomText(
            text:
                statusLabel ??
                (isBlocked
                    ? "Account Blocked"
                    : isSuccess
                    ? 'Successful'
                    : 'Failed'),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          12.height,
          CustomText(
            text:
                message ??
                (isBlocked
                    ? "Your account has been blocked. Please contact support for assistance."
                    : isSuccess
                    ? type == "signup"
                          ? "OTP has been verified. Your account has been created successfully"
                          : "OTP has been verified. Your account has been logged in successfully"
                    : 'Something went wrong during verification'),
            fontSize: 14,
            color: AppColors.lightText,
          ),
          32.height,
          CustomButton(
            text: isBlocked
                ? 'Contact Support'
                : (!isSuccess && onButtonPressed == null)
                ? 'Try Again'
                : buttonText,
            onPressed:
                onButtonPressed ??
                () {
                  Get.back();
                  if (isBlocked) {
                    SupportService.showSupportOptions();
                  } else if (isSuccess) {
                    Get.offAllNamed(AppRoutes.home);
                  }
                },
            color: isSuccess ? AppColors.primary : AppColors.redAccent,
            textColor: AppColors.white,
          ),
          16.height,
        ],
      ),
    );
  }
}
