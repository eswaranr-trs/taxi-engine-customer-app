import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/services/support_service/support_service.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/features/auth/login/controller/login_controller.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/controller/otp_controller.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/timer.dart';
import 'package:orange_taxi_customer_app/features/auth/signup/controller/signup_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

import '../../../../core/custom_widgets/custom_sizedbox/custom_sizedbox.dart' show SpaceExtension;

class OtpBottomSheet extends StatelessWidget {
  final String phoneNumber;
  OtpBottomSheet({super.key, required this.phoneNumber});

  final OtpController controller = Get.find<OtpController>();

  Future<void> _contactSupport() => SupportService.contactSupport();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          20.height,
          Obx(() {
            final bool isBlocked = controller.isLogin.value
                ? controller.isLoginBlocked.value
                : controller.isSignupBlocked.value;
            return CustomText(text: isBlocked ? 'Blocked' : 'OTP Request', fontWeight: FontWeight.bold, fontSize: 18);
          }),

          Obx(() {
            final bool isBlocked = controller.isLogin.value
                ? controller.isLoginBlocked.value
                : controller.isSignupBlocked.value;
            return isBlocked
                ? Obx(
                    () => AnimatedCountdownTimer(
                      duration: controller.actualRemainingSeconds.seconds,
                      totalDuration: controller.actualRemainingSeconds.seconds,
                      color: AppColors.primary,
                    ),
                  )
                : Image.asset('assets/images/otp_request.png', height: 180, width: 280);
          }),
          10.height,

          Obx(() {
            final bool isBlocked = controller.isLogin.value
                ? controller.isLoginBlocked.value
                : controller.isSignupBlocked.value;
            return isBlocked
                ? CustomText(
                    text:
                        "You have exceeded the maximum number of attempts. Please try again after the block is released.",
                    fontSize: 14,
                  )
                : CustomText(text: "Please request an OTP to verify your registered mobile number.", fontSize: 14);
          }),
          20.height,
          Obx(() {
            final String fullPhoneNumber = phoneNumber;
            final bool isBlocked = controller.isLogin.value
                ? controller.isLoginBlocked.value
                : controller.isSignupBlocked.value;
            if (isBlocked) {
              return Column(
                children: [
                  CustomButton(
                    text: 'Contact Support',
                    onPressed: _contactSupport,
                    color: AppColors.primary,
                    textColor: AppColors.white,
                    icon: Icons.call_made,
                  ),
                ],
              );
            }

            if (controller.isLogin.value) {
              final loginController = Get.find<LoginController>();
              return CustomButton(
                text: loginController.isLoading.value ? "Please wait..." : "Request OTP",
                onPressed: loginController.isLoading.value
                    ? () {}
                    : () async {
                        await loginController.requestOtp(fullPhoneNumber);
                      },
                color: AppColors.primary,
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
              );
            } else {
              final signUpController = Get.find<SignUpController>();
              return CustomButton(
                text: signUpController.isLoading.value ? "Please wait..." : "Request OTP",
                onPressed: signUpController.isLoading.value
                    ? () {}
                    : () async {
                        await signUpController.requestOtp(fullPhoneNumber);
                      },
                color: AppColors.primary,
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
              );
            }
          }),
        ],
      ),
    );
  }
}
