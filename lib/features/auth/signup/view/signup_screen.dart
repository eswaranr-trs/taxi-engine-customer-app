import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/utils/back_exit_helper.dart';
import 'package:orange_taxi_customer_app/features/auth/signup/controller/signup_controller.dart' show SignUpController;
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:orange_taxi_customer_app/features/legal/model/legal_document.dart';

import 'package:get/get.dart';

class SignUpScreen extends GetView<SignUpController> {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.35;

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
                    top: 10,
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
                    bottom: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text: "create_account".tr,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        6.height,
                        CustomText(
                          text: "Let's get you started! Fill in the details below.",
                          fontSize: 14,
                          color: AppColors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom white card with the form, overlapping the header
            Positioned(
              top: headerHeight - 55,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 16),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CustomText(text: 'name_label'.tr, fontSize: 13, color: AppColors.normalText),
                        ),
                        3.height,
                        CustomTextField(
                          label: "enter_name".tr,
                          controller: controller.nameController,
                          validator: (value) => controller.validateName(value?.trim()),
                          maxLength: 50,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
                        ),
                        10.height,
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
                                  dropdownColor: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
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
                              child: GetBuilder<SignUpController>(
                                builder: (controller) {
                                  return CustomTextField(
                                    label: "enter_phone".tr,
                                    controller: controller.phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'\d')),
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    maxLength: 10,
                                    onTap: controller.pickPhoneNumberHint,
                                    validator: controller.validatePhone,
                                    suffix:
                                        controller.phoneController.text.length == 10 &&
                                            controller.validatePhone(controller.phoneController.text) == null
                                        ? Icon(Icons.check_circle, color: AppColors.green, size: 25)
                                        : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        10.height,
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CustomText(text: 'email_optional'.tr, fontSize: 13, color: AppColors.normalText),
                        ),
                        3.height,
                        CustomTextField(
                          label: "enter_email".tr,
                          controller: controller.emailController,
                          validator: controller.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        10.height,
                        // Date of birth field commented out (restore later).
                        // Align(
                        //   alignment: Alignment.bottomLeft,
                        //   child: CustomText(text: 'dob_optional'.tr, fontSize: 13, color: AppColors.normalText),
                        // ),
                        // 3.height,
                        // GestureDetector(
                        //   onTap: () => controller.selectDate(context),
                        //   child: AbsorbPointer(
                        //     child: CustomTextField(
                        //       label: "dd_mm_yyyy".tr,
                        //       controller: controller.dobController,
                        //       validator: controller.validateDob,
                        //       readOnly: true,
                        //       suffix: const Icon(Icons.calendar_today, color: AppColors.grey),
                        //     ),
                        //   ),
                        // ),
                        // 10.height,
                        // Referral code field commented out (restore later).
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CustomText(
                            text: 'referral_code_optional'.tr,
                            fontSize: 13,
                            color: AppColors.normalText,
                          ),
                        ),
                        3.height,
                        Obx(
                          () => CustomTextField(
                            label: "enter_referral_code".tr,
                            controller: controller.referralController,
                            onChanged: (value) async {
                              if (value.length > 5) {
                                await controller.validateReferralCode(value);
                              } else {
                                controller.referralError.value = '';
                                controller.referrerName.value = '';
                                controller.isReferralValid.value = false;
                              }
                            },

                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                              LengthLimitingTextInputFormatter(20),
                            ],

                            errorText: controller.referralError.value.isEmpty ? null : controller.referralError.value,
                            suffix: controller.isReferralLoading.value
                                ? SizedBox.shrink()
                                : controller.isReferralValid.value
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          ),
                        ),

                        Obx(() {
                          if (!controller.isReferralValid.value || controller.referrerName.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard, size: 18, color: AppColors.successGreen),
                                10.width,
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 13, color: AppColors.successGreen),
                                      children: [
                                        const TextSpan(text: 'Referred by '),
                                        TextSpan(
                                          text: controller.referrerName.value,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        5.height,
                        Obx(
                          () => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: controller.termsAndPrivacyAccepted.value,
                                onChanged: (value) async {
                                  controller.termsAndPrivacyAccepted.value = value ?? false;

                                  if (value == true) {
                                    await controller.submitConsent();
                                  }
                                },
                                activeColor: AppColors.primary,
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),

                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 13, color: AppColors.normalText),

                                      children: [
                                        TextSpan(text: "${'i_agree_to'.tr} "),

                                        TextSpan(
                                          text: "${'terms_and_conditions'.tr} ",

                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                            color: AppColors.primary,
                                          ),

                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => Get.toNamed(
                                              AppRoutes.legal,
                                              arguments: LegalDocType.termsAndConditions,
                                            ),
                                        ),

                                        TextSpan(text: "${'and'.tr} "),
 
                                        TextSpan(
                                          text: 'privacy_policy'.tr,

                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                            color: AppColors.primary,
                                          ),

                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () =>
                                                Get.toNamed(AppRoutes.legal, arguments: LegalDocType.privacyPolicy),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(
                          () => controller.showTermsError.value && !controller.termsAndPrivacyAccepted.value
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: CustomText(
                                      text:
                                          'Please accept the ${'terms_and_conditions'.tr}${'and'.tr}${'privacy_policy'.tr}',
                                      fontSize: 12,
                                      color: AppColors.error,
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        10.height,
                        CustomButton(
                          text: "signup_btn".tr,
                          color: AppColors.primary,
                          gradient: AppColors.gradientButton,
                          textColor: AppColors.white,
                          onPressed: controller.submit,
                        ),

                        5.height,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: CustomText(text: 'or', fontWeight: FontWeight.bold, color: AppColors.lightText),
                        ),
                        10.height,
                        Obx(() {
                          final loading = controller.isLoading.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: loading ? null : controller.signUpWithGoogle,
                            child: Container(
                              height: 58,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.grey300),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: loading
                                    ? [
                                        const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                        ),
                                        12.width,
                                        CustomText(
                                          text: 'Signing up...',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.normalText,
                                        ),
                                      ]
                                    : [
                                        Image.asset('assets/images/google_logo.png', height: 24, width: 24),
                                        12.width,
                                        CustomText(
                                          text: 'signup_with_google'.tr,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.normalText,
                                        ),
                                      ],
                              ),
                            ),
                          );
                        }),
                        10.height,
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14, color: AppColors.normalText),
                            children: [
                              TextSpan(
                                text: "already_have_account".tr,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.normalText),
                              ),
                              TextSpan(
                                text: "login_link".tr,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () => Get.offNamed('/login'),
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
