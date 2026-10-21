import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../config/themes/app_colors.dart';
import '../../../../core/custom_widgets/custom_button/custom_button.dart';
import '../../../../core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import '../../../../core/custom_widgets/custom_text/custom_text.dart';
import '../controller/otp_controller.dart';

class OtpVerificationScreen extends GetView<OtpController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: const CustomText(
          text: 'OTP Verification',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/otp_verification.png', height: 250, width: 350),

                  const CustomText(
                    text: 'We have sent the verification code to your\nMobile Number',
                    fontSize: 14,
                    color: AppColors.lightText,
                  ),

                  20.height,

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => CustomText(
                          text: controller.phoneNumber.value,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),

                      8.width,

                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.grey),
                      ),
                    ],
                  ),

                  20.height,

                  SizedBox(
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TextField(
                          controller: controller.textController,
                          focusNode: controller.focusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          // autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'\d')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          autofocus: true,
                          maxLength: 6,
                          cursorColor: AppColors.transparent,
                          style: const TextStyle(color: AppColors.transparent, fontSize: 1),
                          decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                          onChanged: (value) {
                            controller.otp.value = value;

                            if (value.length == 6) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),

                        IgnorePointer(
                          child: Obx(
                            () => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) => _buildOtpBox(index)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  10.height,

                  // Obx(() {
                  //   final int attempts = controller.isLogin.value
                  //       ? controller.loginAttemptsLeft.value
                  //       : controller.signupAttemptsLeft.value;
                  //   return CustomText(
                  //     text: "Attempts left: $attempts",
                  //     fontSize: 14,
                  //     color: attempts == 1 ? AppColors.red : AppColors.lightText,
                  //   );
                  // }),

                  // 10.height,
                  Row(
                    children: [
                      const CustomText(text: "Didn't get OTP code? ", fontSize: 14, color: AppColors.lightText),

                      Obx(
                        () => InkWell(
                          onTap: controller.canResend.value ? () => controller.resendOtp() : null,
                          child: CustomText(
                            text: controller.canResend.value
                                ? "Resend OTP"
                                : "Resend in 00:${controller.resendTimerSeconds.value.toString().padLeft(2, '0')}",
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: controller.canResend.value ? AppColors.black : AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  50.height,

                  Obx(
                    () => CustomButton(
                      text: controller.isLoading.value ? "Verifying..." : "Verify OTP",
                      onPressed: (controller.otp.value.length == 6 && !controller.isLoading.value)
                          ? controller.verifyOtp
                          : () {},

                      gradient: AppColors.gradientButton,
                      textColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    String char = "";

    if (controller.otp.value.length > index) {
      char = controller.otp.value[index];
    }

    bool isFocused = controller.otp.value.length == index || (index == 5 && controller.otp.value.length == 6);

    return Container(
      width: 48,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFocused ? AppColors.primary : AppColors.grey300, width: isFocused ? 2 : 1.5),
      ),
      alignment: Alignment.center,
      child: CustomText(text: char, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.black),
    );
  }
}
