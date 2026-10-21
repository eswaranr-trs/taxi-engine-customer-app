import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/core/services/location_service/location_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/widgets/otp_status_bottomsheet.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_auth/smart_auth.dart';

class OtpController extends GetxController {
  final textController = TextEditingController();
  final focusNode = FocusNode();
  var otp = ''.obs;
  RxString phoneNumber = ''.obs;

  var smsToken = ''.obs;
  var name = ''.obs;
  var email = ''.obs;
  var dateOfBirth = ''.obs;
  var referralCode = ''.obs;
  var deviceId = ''.obs;
  var marketingConsent = false.obs;
  var isLogin = false.obs;
  var isLoading = false.obs;
  final RxBool isResendingOtp = false.obs;
  Timer? _timer;

  var resendTimerSeconds = 60.obs;
  var canResend = false.obs;

  RxInt loginAttemptsLeft = 0.obs;
  RxInt signupAttemptsLeft = 0.obs;

  RxBool isLoginBlocked = false.obs;
  RxBool isSignupBlocked = false.obs;

  Rxn<DateTime> loginRemainingBlockTime = Rxn<DateTime>();
  Rxn<DateTime> signupRemainingBlockTime = Rxn<DateTime>();

  final formKey = GlobalKey<FormState>();

  int get actualRemainingSeconds {
    final time = isLogin.value ? loginRemainingBlockTime.value : signupRemainingBlockTime.value;
    if (time == null) return 0;
    final diff = time.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      if (Get.arguments is String) {
        phoneNumber.value = Get.arguments;
      } else if (Get.arguments is Map) {
        phoneNumber.value = Get.arguments['phone'] ?? "";
        smsToken.value = Get.arguments['smsToken'] ?? "";
        name.value = Get.arguments['name'] ?? "";
        isLogin.value = Get.arguments['isLogin'] ?? false;
      }
    }

    textController.addListener(() {
      otp.value = textController.text;
    });

    startResendTimer();
    _loadPersistedBlockTimes();
    // logAppSignature();
    // _startSmsListener();
  }

  Future<String?> logAppSignature() async {
    if (!kDebugMode || !GetPlatform.isAndroid) return null;
    final res = await SmartAuth.instance.getAppSignature();
    final String? appSignature = res.data;
    debugPrint('App Signature: $appSignature');
    if (appSignature == null) debugPrint('App Signature failed: ${res.error}');
    return appSignature;
  }

  Future<void> _startSmsListener() async {
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi(matcher: r'\d{6}');
      final code = res.data?.code;
      if (code != null && code.isNotEmpty) {
        textController.text = code;
        otp.value = code;
        final bool blocked = isLogin.value ? isLoginBlocked.value : isSignupBlocked.value;
        if (code.length == 6 && !isLoading.value && !blocked) {
          verifyOtp();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPersistedBlockTimes() async {
    final loginBlockTime = await LocalStorageService.getLoginBlockTime();
    if (loginBlockTime != null) {
      if (loginBlockTime.isAfter(DateTime.now())) {
        isLoginBlocked.value = true;
        loginRemainingBlockTime.value = loginBlockTime;
        _scheduleUnblock(loginBlockTime, true);
      } else {
        await LocalStorageService.setLoginBlockTime(null);
      }
    }

    final signupBlockTime = await LocalStorageService.getSignupBlockTime();
    if (signupBlockTime != null) {
      if (signupBlockTime.isAfter(DateTime.now())) {
        isSignupBlocked.value = true;
        signupRemainingBlockTime.value = signupBlockTime;
        _scheduleUnblock(signupBlockTime, false);
      } else {
        await LocalStorageService.setSignupBlockTime(null);
      }
    }
  }

  String get calculatedRemainingBlockTime {
    final time = isLogin.value ? loginRemainingBlockTime.value : signupRemainingBlockTime.value;
    if (time == null) {
      return '';
    }

    final Duration difference = time.difference(DateTime.now());

    if (difference.inSeconds <= 0) {
      return '';
    }

    int totalSeconds = difference.inSeconds;
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  Future<void> handleBlockStatusFromResponse(Map<String, dynamic> response) async {
    if (isLogin.value) {
      loginAttemptsLeft.value = response['attemptsLeft'] ?? 0;
      isLoginBlocked.value = response['blockStatus'] ?? false;
      if (isLoginBlocked.value) {
        final String remainingTimeStr = response['remainingBlockTime'] ?? "00:00:00";
        if (remainingTimeStr != "00:00:00") {
          List<String> parts = remainingTimeStr.split(':');
          if (parts.length == 3) {
            int seconds = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
            final DateTime blockTime = DateTime.now().add(Duration(seconds: seconds));
            loginRemainingBlockTime.value = blockTime;
            await LocalStorageService.setLoginBlockTime(blockTime);
            _scheduleUnblock(blockTime, true);
          }
        }
      } else {
        loginRemainingBlockTime.value = null;
        await LocalStorageService.setLoginBlockTime(null);
      }
    } else {
      signupAttemptsLeft.value = response['attemptsLeft'] ?? 0;
      isSignupBlocked.value = response['blockStatus'] ?? false;
      if (isSignupBlocked.value) {
        final String remainingTimeStr = response['remainingBlockTime'] ?? "00:00:00";
        if (remainingTimeStr != "00:00:00") {
          List<String> parts = remainingTimeStr.split(':');
          if (parts.length == 3) {
            int seconds = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
            final DateTime blockTime = DateTime.now().add(Duration(seconds: seconds));
            signupRemainingBlockTime.value = blockTime;
            await LocalStorageService.setSignupBlockTime(blockTime);
            _scheduleUnblock(blockTime, false);
          }
        }
      } else {
        signupRemainingBlockTime.value = null;
        await LocalStorageService.setSignupBlockTime(null);
      }
    }
  }

  void setBlockFromSeconds(int seconds) {
    final bool blocked = seconds > 0;
    final DateTime? until = blocked ? DateTime.now().add(Duration(seconds: seconds)) : null;
    if (isLogin.value) {
      isLoginBlocked.value = blocked;
      loginRemainingBlockTime.value = until;
    } else {
      isSignupBlocked.value = blocked;
      signupRemainingBlockTime.value = until;
    }
  }

  void _scheduleUnblock(DateTime blockTime, bool forLogin) {
    final delay = blockTime.difference(DateTime.now());

    Future<void> unblock() async {
      if (forLogin) {
        if (loginRemainingBlockTime.value == blockTime) {
          isLoginBlocked.value = false;
          loginRemainingBlockTime.value = null;
          await LocalStorageService.setLoginBlockTime(null);
        }
      } else {
        if (signupRemainingBlockTime.value == blockTime) {
          isSignupBlocked.value = false;
          signupRemainingBlockTime.value = null;
          await LocalStorageService.setSignupBlockTime(null);
        }
      }
    }

    if (delay.isNegative) {
      unblock();
      return;
    }

    if (forLogin) {
      _loginUnblockTimer?.cancel();
      _loginUnblockTimer = Timer(delay, unblock);
    } else {
      _signupUnblockTimer?.cancel();
      _signupUnblockTimer = Timer(delay, unblock);
    }
  }

  Timer? _loginUnblockTimer;
  Timer? _signupUnblockTimer;

  void startResendTimer() {
    canResend.value = false;
    resendTimerSeconds.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimerSeconds.value > 0) {
        resendTimerSeconds.value--;
      } else {
        canResend.value = true;
        _timer?.cancel();
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    _loginUnblockTimer?.cancel();
    _signupUnblockTimer?.cancel();
    SmartAuth.instance.removeUserConsentApiListener();
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void addDigit(String digit) {
    if (otp.value.length < 6) {
      textController.text += digit;
    }
  }

  void removeDigit() {
    if (otp.value.isNotEmpty) {
      textController.text = otp.value.substring(0, otp.value.length - 1);
    }
  }

  void clearOtp() {
    textController.clear();
    otp.value = '';
  }

  Future<void> verifyOtp() async {
    final bool currentIsBlocked = isLogin.value ? isLoginBlocked.value : isSignupBlocked.value;
    if (currentIsBlocked) {
      final String remainingTime = calculatedRemainingBlockTime;

      await Get.bottomSheet(
        OtpStatusBottomSheet(
          isSuccess: false,
          title: "Blocked",
          message:
              'Too many failed attempts.\n'
              'Try again after $remainingTime',
        ),
      );
      return;
    }

    try {
      isLoading.value = true;
      final String cleanPhone = phoneNumber.value.replaceAll(' ', '');
      Map<String, dynamic>? responseData;
      final String? locale = await LocalStorageService.getLanguage();

      final String language = locale?.split('_').first.toLowerCase() ?? 'en';
      Position position = await Geolocator.getCurrentPosition();
      String currentLocation = "${position.latitude},${position.longitude}";

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      final geo = await LocationService().getGeoDetails(position.latitude, position.longitude);
      final String deviceModel = await AppConstants.getDeviceModel();

      if (isLogin.value) {
        responseData = await Get.find<AuthRepository>().verifyLoginOtp(
          phone: cleanPhone,
          otp: otp.value,
          geoLocation: currentLocation,
          fcmToken: fcmToken ?? "",
          deviceModel: deviceModel,
          platform: AppConstants.platform,
          appVersion: AppConstants.appVersion,
          country: geo['country'] ?? '',
          state: geo['state'] ?? '',
          city: geo['city'] ?? '',
        );
      } else {
        responseData = await Get.find<AuthRepository>().verifySignUpOtp(
          phone: cleanPhone,
          otp: otp.value,
          smsToken: smsToken.value,
          name: name.value,
          fcmToken: fcmToken ?? "",
          email: email.value,
          dateOfBirth: dateOfBirth.value,
          deviceId: deviceId.value,
          marketingConsent: marketingConsent.value,
          language: language,
          geoLocation: currentLocation,
          referralCode: referralCode.value,
          deviceModel: deviceModel,
          platform: AppConstants.platform,
          appVersion: AppConstants.appVersion,
          country: geo['country'] ?? '',
          state: geo['state'] ?? '',
          city: geo['city'] ?? '',
        );
      }

      if (!isLogin.value && responseData != null && responseData['isNewUser'] == false) {
        isLoading.value = false;
        await Get.bottomSheet(
          OtpStatusBottomSheet(
            isSuccess: false,
            type: "signup",
            title: "Account Exists",
            statusLabel: "Account Exists",
            message: "This number is already registered. Please log in instead.",
            buttonText: "Go to Login",
            onButtonPressed: () {
              Get.back();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        );
        return;
      }

      await LocalStorageService.setIsSignupUser(!isLogin.value);

      if (responseData != null) {
        final token = responseData['token'];
        final user = responseData['user'];

        if (token != null) {
          await SecureStorageService.saveAuthToken(token);
        }

        if (user != null) {
          await LocalStorageService.saveUser(user);
        }

        await LocalStorageService.setLoggedIn(true);
        await LocalStorageService.saveLastActiveTime();

        final auth = Get.find<AuthRepository>();
        auth.listenFcmRefresh();
        auth.syncFcmToken();

        if (isLogin.value) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_given_consent', true);
        }
      }

      await Get.bottomSheet(
        PopScope(canPop: false, child: OtpStatusBottomSheet(isSuccess: true)),
        isDismissible: false,
        enableDrag: false,
      );
    } catch (e) {
      String message = "Something went wrong";

      if (e is ApiException) {
        message = e.message;
        if (e.data != null && e.data is Map<String, dynamic>) {
          handleBlockStatusFromResponse(e.data);
        } else {
          if (!message.toLowerCase().contains('deactivated')) {
            if (isLogin.value) {
              loginAttemptsLeft.value--;
            } else {
              signupAttemptsLeft.value--;
            }
          }
        }
      } else {
        final String error = e.toString();
        final Match? jsonMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(error);
        final Match? match = RegExp(r'message:\s*([^,}]+)').firstMatch(error);

        if (jsonMatch != null) {
          message = jsonMatch.group(1)?.trim() ?? message;
        } else if (match != null) {
          message = match.group(1)?.trim() ?? message;
        } else {
          message = error;
        }

        if (!message.toLowerCase().contains('deactivated')) {
          if (isLogin.value) {
            loginAttemptsLeft.value--;
          } else {
            signupAttemptsLeft.value--;
          }
        }
      }

      if (message.toLowerCase().contains('deactivated')) {
        await Get.bottomSheet(OtpStatusBottomSheet(isSuccess: false, title: "Account Deactivated", message: message));
        Get.back();
      } else {
        if (isLogin.value) {
          if (loginAttemptsLeft.value <= 0 && !isLoginBlocked.value) {
            final DateTime blockTime = DateTime.now().add(const Duration(seconds: 30));
            loginRemainingBlockTime.value = blockTime;
            isLoginBlocked.value = true;
            await LocalStorageService.setLoginBlockTime(blockTime);
            _scheduleUnblock(blockTime, true);
          }
        } else {
          if (signupAttemptsLeft.value <= 0 && !isSignupBlocked.value) {
            final DateTime blockTime = DateTime.now().add(const Duration(seconds: 30));
            signupRemainingBlockTime.value = blockTime;
            isSignupBlocked.value = true;
            await LocalStorageService.setSignupBlockTime(blockTime);
            _scheduleUnblock(blockTime, false);
          }
        }

        final bool currentlyBlocked = isLogin.value ? isLoginBlocked.value : isSignupBlocked.value;
        if (currentlyBlocked) {
          await Get.bottomSheet(
            OtpStatusBottomSheet(isSuccess: false, isBlocked: true, title: "Account Locked", message: message),
          );
          Get.back();
          Get.back();
        } else {
          await Get.bottomSheet(OtpStatusBottomSheet(isSuccess: false, title: "Verification Failed", message: message));
        }
      }
    } finally {
      isLoading.value = false;
      textController.clear();
    }
  }

  Future<void> resendOtp() async {
    final bool currentIsBlocked = isLogin.value ? isLoginBlocked.value : isSignupBlocked.value;

    if (!canResend.value || currentIsBlocked) return;

    try {
      isResendingOtp.value = true;
      final cleanPhone = phoneNumber.value.replaceAll(' ', '');

      if (isLogin.value) {
        await Get.find<AuthRepository>().sendLoginOtp(cleanPhone);
      } else {
        await Get.find<AuthRepository>().sendSignUpOtp(cleanPhone, '');
      }

      clearOtp();
      startResendTimer();
      _startSmsListener();
    } catch (e) {
      AppSnackbar.error("Error", e.toString());
    } finally {
      isResendingOtp.value = false;
    }
  }
}
