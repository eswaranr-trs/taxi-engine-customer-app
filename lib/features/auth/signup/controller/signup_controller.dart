import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/core/services/support_service/support_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/controller/otp_controller.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/otp_request_bottomsheet.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/otp_status_bottomsheet.dart';

import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';

class SignUpController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final referralController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var isValid = false.obs;
  var selectedCode = "+91".obs;
  RxBool termsAndPrivacyAccepted = false.obs;
  final RxBool showTermsError = false.obs;

  final List<Map<String, String>> countryCodes = [
    {"code": "+91", "flag": "🇮🇳"},
  ];

  final RxString referralError = ''.obs;
  final RxString referrerName = ''.obs;

  final RxBool isReferralValid = false.obs;

  final RxBool isReferralLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_validate);
    phoneController.addListener(_validate);
    emailController.addListener(_validate);
    dobController.addListener(_validate);
    ever(termsAndPrivacyAccepted, (_) => _validate());
  }

  void _validate() {
    isValid.value =
        validateName(nameController.text) == null &&
        validatePhone(phoneController.text) == null &&
        (emailController.text.isEmpty || validateEmail(emailController.text) == null) &&
        (dobController.text.isEmpty || validateDob(dobController.text) == null) &&
        termsAndPrivacyAccepted.value;
    update();
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

  Future<void> submitConsent() async {
    try {
      String ipAddress = 'unknown';
      try {
        final response = await Dio().get('https://api.ipify.org?format=json');
        if (response.statusCode == 200) {
          ipAddress = response.data['ip'];
        }
      } catch (_) {}

      final timestamp = DateTime.now().toUtc().toIso8601String();
      const policyVersion = 'v1.0';

      await LocalStorageService.saveConsentData(ipAddress, timestamp, policyVersion);
    } catch (_) {}
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 365 * 18));

    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 350,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          color: AppColors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        dobController.clear();
                        Navigator.pop(context);
                      },
                      child: CustomText(text: "Clear", fontSize: 16, color: AppColors.normalText),
                    ),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        dobController.text =
                            "${selectedDate.day.toString().padLeft(2, '0')}/"
                            "${selectedDate.month.toString().padLeft(2, '0')}/"
                            "${selectedDate.year}";

                        _validate();
                        Navigator.pop(context);
                      },
                      child: CustomText(
                        text: "Done",
                        fontSize: 16,
                        color: AppColors.normalText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1950),
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!GetUtils.isEmail(value.trim())) {
      return "Enter valid email address";
    }

    return null;
  }

  String? validateDob(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    try {
      final parts = value.split('/');

      final dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));

      final today = DateTime.now();

      int age = today.year - dob.year;

      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      if (age < 18) {
        return "You must be at least 18 years old";
      }
    } catch (e) {
      return "Invalid date format";
    }

    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Name is required";
    }

    value = value.trim();

    if (value.length < 2) {
      return "Name must be at least 2 characters";
    } else if (value.length > 50) {
      return "Name must be less than 50 characters";
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return "Only alphabets are allowed";
    }

    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number is required";
    }
    if (value.length != 10) {
      return "Must be 10 digits";
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return "Invalid Phone number";
    }
    return null;
  }

  var isLoading = false.obs;

  void submit() async {
    if (Get.isBottomSheetOpen ?? false) return;

    final bool formOk = formKey.currentState!.validate();
    showTermsError.value = !termsAndPrivacyAccepted.value;
    if (!formOk || !termsAndPrivacyAccepted.value) return;

    final otpCtrl = Get.put(OtpController());
    otpCtrl.isLogin.value = false;

    isLoading.value = true;
    final lock = await Get.find<AuthRepository>().getLockStatus(phoneController.text.trim());
    isLoading.value = false;
    final bool blocked = lock?['locked'] == true;
    otpCtrl.setBlockFromSeconds(blocked ? _int(lock?['remainingSeconds']) : 0);

    await Get.bottomSheet(OtpBottomSheet(phoneNumber: phoneController.text), isScrollControlled: true);
  }

  int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> _persistSession(Map<String, dynamic> response) async {
    final data = response['data'];
    if (data is Map && data['user'] != null) {
      await LocalStorageService.saveUser(Map<String, dynamic>.from(data['user']));
    }
    await LocalStorageService.setLoggedIn(true);
    await LocalStorageService.saveLastActiveTime();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleServerClientId,
    scopes: const ['email'],
  );

  Future<void> signUpWithGoogle() async {
    try {
      isLoading.value = true;

      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        AppSnackbar.error('Google Sign-Up', 'Could not get Google token');
        return;
      }

      final String name = userCredential.user?.displayName ?? '';
      final String email = userCredential.user?.email ?? '';

      String phone = _last10Digits(userCredential.user?.phoneNumber ?? '');
      if (phone.isEmpty) {
        isLoading.value = false;
        final entered = await _askPhoneNumber();
        if (entered == null || entered.isEmpty) {
          await _googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
          return;
        }
        phone = entered;
        isLoading.value = true;
      }

      final response = await Get.find<AuthRepository>().signUpOauth(
        idToken,
        phone: phone,
        email: email,
        name: name,
        marketingConsent: termsAndPrivacyAccepted.value,
      );
      if (response != null && response['success'] == true) {
        final data = response['data'];
        final bool existingAccount = data is Map && data['isNewUser'] == false;
        if (existingAccount) {
          await _showAccountExistsSheet();
          return;
        }

        await SecureStorageService.saveResponseData(response);
        await _persistSession(response);
        await LocalStorageService.setIsSignupUser(true);
        Get.offAllNamed(AppRoutes.home);
        AppSnackbar.success('Success', response['message']?.toString() ?? 'Signed up successfully');
      } else {
        final String msg = response?['message']?.toString() ?? 'Google Sign-Up failed';
        if (_isAccountExists(msg)) {
          await _showAccountExistsSheet(message: msg);
        } else {
          AppSnackbar.error('Google Sign-Up', msg);
        }
      }
    } on ApiException catch (e) {
      if (_isAccountExists(e.message)) {
        await _showAccountExistsSheet(message: e.message);
      } else {
        AppSnackbar.error('Google Sign-Up', e.message);
      }
    } catch (e) {
      debugPrint("oauth error $e");
      AppSnackbar.error('Google Sign-Up', 'Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  bool _isAccountExists(String message) => message.toLowerCase().contains('already exist');

  Future<void> _showAccountExistsSheet({String? message}) async {
    await _googleSignIn.signOut();
    if (!Get.isRegistered<OtpController>()) Get.put(OtpController());
    await Get.bottomSheet(
      OtpStatusBottomSheet(
        isSuccess: false,
        type: "signup",
        title: "Account Exists",
        message: message ?? 'This account is already registered. Please log in with your email or phone number.',
        statusLabel: "Account Exists",
        buttonText: "Go to Login",
        onButtonPressed: () {
          Get.back();
          Get.offAllNamed(AppRoutes.login);
        },
      ),
    );
  }

  Future<void> requestOtp(final String fullPhoneNumber) async {
    try {
      isLoading.value = true;
      final cleanPhone = fullPhoneNumber.replaceAll(' ', '');
      final response = await Get.find<AuthRepository>().sendSignUpOtp(cleanPhone, referralController.text.trim());

      Get.back();
      final otpCtrl = Get.find<OtpController>();
      otpCtrl.phoneNumber.value = fullPhoneNumber;
      otpCtrl.name.value = nameController.text;
      otpCtrl.email.value = emailController.text;
      otpCtrl.dateOfBirth.value = dobController.text;
      otpCtrl.referralCode.value = referralController.text;
      otpCtrl.marketingConsent.value = termsAndPrivacyAccepted.value;
      otpCtrl.deviceId.value = await AppConstants.getDeviceId();
      otpCtrl.isLogin.value = false;

      if (response != null && response['success'] == true) {
        otpCtrl.handleBlockStatusFromResponse(response);
        otpCtrl.clearOtp();
        await Get.toNamed(AppRoutes.otpVerification);
      } else {
        final String msg = (response?['message'] ?? '').toString();
        final String msgLc = msg.toLowerCase();
        final bool accountDeleted = msgLc.contains('deleted');
        final bool accountExists =
            !accountDeleted && (msgLc.contains('already') || msgLc.contains('exist') || msgLc.contains('registered'));
        await Get.bottomSheet(
          OtpStatusBottomSheet(
            isSuccess: false,
            type: "signup",
            title: accountDeleted
                ? 'Account Deleted'
                : accountExists
                ? 'Account Exists'
                : response?['title'],
            message: response?['message'],
            statusLabel: accountDeleted
                ? 'Account Deleted'
                : accountExists
                ? 'Account Exists'
                : null,
            buttonText: accountDeleted
                ? 'Contact Admin'
                : accountExists
                ? 'Go to Login'
                : 'Try Again',
            onButtonPressed: accountDeleted
                ? () {
                    Get.back();
                    SupportService.showSupportOptions();
                  }
                : accountExists
                ? () {
                    Get.back();
                    Get.offAllNamed(AppRoutes.login);
                  }
                : null,
          ),
        );
      }
    } on ApiException catch (e) {
      String title = "Something went wrong";
      String message = "Please try again";

      final data = e.data;
      if (data is Map<String, dynamic>) {
        message = data['error']?['message'] ?? data['message'] ?? e.message;

        final otpCtrl = Get.find<OtpController>();
        otpCtrl.handleBlockStatusFromResponse(data);

        if (data['blockStatus'] == true) {
          return;
        }
      } else {
        message = e.message;
      }

      final String msgLc = message.toLowerCase();
      final bool accountDeleted = msgLc.contains('deleted');
      final bool accountExists =
          !accountDeleted &&
          (e.statusCode == 409 || msgLc.contains('already') || msgLc.contains('exist') || msgLc.contains('registered'));
      if (accountDeleted) {
        title = "Account Deleted";
      } else if (accountExists) {
        title = "Account Exists";
      }

      Get.back();
      await Get.bottomSheet(
        OtpStatusBottomSheet(
          isSuccess: false,
          type: "signup",
          title: title,
          message: message,
          statusLabel: accountDeleted
              ? "Account Deleted"
              : accountExists
              ? "Account Exists"
              : null,
          buttonText: accountDeleted
              ? "Contact Admin"
              : accountExists
              ? "Go to Login"
              : "Try Again",
          onButtonPressed: accountDeleted
              ? () {
                  Get.back();
                  SupportService.showSupportOptions();
                }
              : accountExists
              ? () {
                  Get.back();
                  Get.offAllNamed(AppRoutes.login);
                }
              : null,
        ),
      );
    } catch (e) {
      Get.back();
      await Get.bottomSheet(
        OtpStatusBottomSheet(isSuccess: false, type: "signup", title: "Something went wrong", message: e.toString()),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _last10Digits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<String?> _askPhoneNumber() async {
    final TextEditingController phoneCtrl = TextEditingController();
    final result = await Get.bottomSheet<String>(
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              20.height,
              const CustomText(
                text: 'Add your phone number',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                textAlign: TextAlign.start,
              ),
              8.height,
              const CustomText(
                text: 'We need your mobile number to finish signing up with Google.',
                fontSize: 13,
                color: AppColors.grey,
                textAlign: TextAlign.start,
              ),
              20.height,
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
                        initialValue: selectedCode.value,
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
                        items: countryCodes.map((country) {
                          return DropdownMenuItem<String>(
                            value: country["code"],
                            child: CustomText(text: '${country["flag"]} ${country["code"]}', fontSize: 13),
                          );
                        }).toList(),
                        onChanged: (value) => selectedCode.value = value!,
                      ),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: GetBuilder<SignUpController>(
                      builder: (controller) {
                        return CustomTextField(
                          label: "enter_phone".tr,
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'\d')),
                            LengthLimitingTextInputFormatter(10),
                          ],
                          maxLength: 10,
                          validator: controller.validatePhone,
                          suffix: phoneCtrl.text.length == 10 && controller.validatePhone(phoneCtrl.text) == null
                              ? Icon(Icons.check_circle, color: AppColors.green, size: 25)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              20.height,
              CustomButton(
                text: 'Continue',
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
                onPressed: () {
                  final v = phoneCtrl.text.trim();
                  final err = validatePhone(v);
                  if (err != null) {
                    AppSnackbar.error('Invalid phone', err);
                    return;
                  }
                  Get.back(result: v);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );

    Future.delayed(const Duration(milliseconds: 400), phoneCtrl.dispose);
    return result;
  }

  Future<void> validateReferralCode(String referralCode) async {
    try {
      isReferralLoading.value = true;
      referralError.value = '';
      referrerName.value = '';
      final String response = await Get.find<AuthRepository>().validateRefferal(referralCode);
      isReferralValid.value = true;
      referrerName.value = response;
    } catch (e) {
      isReferralValid.value = false;
      referrerName.value = '';
      referralError.value = e is ApiException ? e.message : 'Invalid referral code';
    } finally {
      isReferralLoading.value = false;
    }
  }
}
