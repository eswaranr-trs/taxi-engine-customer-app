import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';

import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/controller/otp_controller.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/otp_request_bottomsheet.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/otp_status_bottomsheet.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var isValid = false.obs;
  var selectedCode = "+91".obs;
  var rememberMe = false.obs;

  final List<Map<String, String>> countryCodes = [
    {"code": "+91", "flag": "🇮🇳"},
  ];

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_validate);
  }

  void _validate() {
    isValid.value = phoneController.text.length == 10;
  }

  bool _hintInFlight = false;
  bool _hintAsked = false;

  Future<void> pickPhoneNumberHint() async {
    if (_hintAsked || _hintInFlight || phoneController.text.isNotEmpty) return;
    _hintAsked = true;
    _hintInFlight = true;
    try {
      final res = await SmartAuth.instance.requestPhoneNumberHint();
      if (res.hasData) {
        final digits = res.data!.replaceAll(RegExp(r'\D'), '');
        phoneController.text = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
      }
    } catch (_) {
    } finally {
      _hintInFlight = false;
    }
  }

  String? validatePhone(final String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";
    if (value.length != 10) return "Must be 10 digits";
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return "Invalid Phone number";
    return null;
  }

  var isLoading = false.obs;
  bool _submittingOtp = false;

  void submit() async {
    if (_submittingOtp || (Get.isBottomSheetOpen ?? false)) return;
    if (!formKey.currentState!.validate()) return;
    _submittingOtp = true;
    try {
      FocusManager.instance.primaryFocus?.unfocus();

      final otpCtrl = Get.put(OtpController());
      otpCtrl.isLogin.value = true;

      isLoading.value = true;
      final lock = await Get.find<AuthRepository>().getLockStatus(phoneController.text.trim());
      isLoading.value = false;
      final bool blocked = lock?['locked'] == true;
      otpCtrl.setBlockFromSeconds(blocked ? _int(lock?['remainingSeconds']) : 0);

      await Future.delayed(const Duration(milliseconds: 200));
      await Get.bottomSheet(OtpBottomSheet(phoneNumber: phoneController.text), isScrollControlled: true);
    } finally {
      isLoading.value = false;
      _submittingOtp = false;
    }
  }

  int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> requestOtp(final String fullPhoneNumber) async {
    try {
      isLoading.value = true;
      final String cleanPhone = fullPhoneNumber.replaceAll(' ', '');
      final response = await Get.find<AuthRepository>().sendLoginOtp(cleanPhone);

      Get.back();

      final OtpController otpCtrl = Get.find<OtpController>();
      otpCtrl.phoneNumber.value = fullPhoneNumber;
      otpCtrl.isLogin.value = true;

      if (response != null) {
        await otpCtrl.handleBlockStatusFromResponse(response);
      }

      otpCtrl.clearOtp();
      AppSnackbar.success("Success", response?['message'] as String? ?? 'OTP sent successfully');
      await Get.toNamed(AppRoutes.otpVerification);
    } on ApiException catch (e) {
      final data = e.data;
      if (data != null && data is Map<String, dynamic>) {
        await Get.find<OtpController>().handleBlockStatusFromResponse(data);
        if (data['blockStatus'] == true) {
          return;
        }
      }

      Get.back();
      final String msgLc = e.message.toLowerCase();
      final bool noAccount = msgLc.contains('no account') || msgLc.contains('not found') || msgLc.contains('sign up');
      await Get.bottomSheet(
        OtpStatusBottomSheet(
          isSuccess: false,
          type: "login",
          title: noAccount ? "Account Not Found" : "OTP Request",
          message: e.message,
          statusLabel: noAccount ? "Account Not Found" : null,
          buttonText: noAccount ? "Go to Sign Up" : "Try Again",
          onButtonPressed: noAccount
              ? () {
                  Get.back();
                  Get.offAllNamed(AppRoutes.signup);
                }
              : null,
        ),
      );
    } catch (e) {
      Get.back();

      await Get.bottomSheet(
        OtpStatusBottomSheet(isSuccess: false, type: "login", title: "OTP Request", message: "Something went wrong"),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
