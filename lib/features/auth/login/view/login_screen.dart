import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/utils/back_exit_helper.dart';
import 'package:orange_taxi_customer_app/features/auth/login/controller/login_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_textfield/custom_textfield.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.42;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (shouldExitOnBack()) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.orange],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/images/auth_background.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text: "login_title".tr,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        6.height,
                        CustomText(text: "login_subtitle".tr, fontSize: 14, color: AppColors.white70),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: headerHeight - 28,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CustomText(text: 'phone_number'.tr, fontSize: 13, color: AppColors.normalText),
                        ),
                        3.height,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => SizedBox(
                                width: 104,
                                child: DropdownButtonFormField<String>(
                                  initialValue: controller.selectedCode.value,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.grey)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.grey, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: controller.countryCodes.map((country) {
                                    return DropdownMenuItem<String>(
                                      value: country["code"],
                                      child: CustomText(text: '${country["flag"]} ${country["code"]}', fontSize: 13),
                                    );
                                  }).toList(),
                                  onChanged: (value) => controller.selectedCode.value = value!,
                                ),
                              ),
                            ),

                            10.width,

                            Expanded(
                              child: Obx(
                                () => CustomTextField(
                                  label: "enter_phone".tr,
                                  controller: controller.phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  onTap: controller.pickPhoneNumberHint,
                                  validator: controller.validatePhone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'\d')),
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  suffix:
                                      controller.isValid.value &&
                                          controller.validatePhone(controller.phoneController.text) == null
                                      ? Icon(Icons.check_circle, color: AppColors.green, size: 25)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),

                        16.height,

                        Obx(
                          () => Row(
                            children: [
                              SizedBox(
                                height: 22,
                                width: 22,
                                child: Checkbox(
                                  value: controller.rememberMe.value,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  onChanged: (bool? value) {
                                    controller.rememberMe.value = value ?? false;
                                  },
                                ),
                              ),

                              10.width,
                              CustomText(text: 'Remember me', fontSize: 14, color: AppColors.normalText),
                            ],
                          ),
                        ),

                        30.height,
                        CustomButton(
                          text: "login_title".tr,
                          color: AppColors.primary,
                          gradient: AppColors.gradientButton,
                          textColor: AppColors.white,
                          onPressed: controller.submit,
                        ),

                        20.height,

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.normalText),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Sign Up",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () => Get.offNamed('/signup'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
