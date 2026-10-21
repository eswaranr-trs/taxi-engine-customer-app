import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import '../../../core/services/network_service/api_service.dart';
import '../../../config/constants/app_endpoints.dart';

class AuthRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<String?> getConfigValue(String keyName) async {
    try {
      final response = await _apiService.get(AppEndpoints.authConfig(keyName));
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']?['keyValue']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getConfigList(String keyName) async {
    try {
      final response = await _apiService.get(AppEndpoints.authConfig(keyName));
      if (response.statusCode == 200 && response.data['success'] == true) {
        final v = response.data['data']?['keyValue'];
        if (v is List) return v.map((e) => e.toString()).toList();
        if (v is String && v.isNotEmpty) return [v];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendSignUpOtp(final String phoneNumber, final String referralCode) async {
    try {
      String deviceId = await AppConstants.getDeviceId();

      final response = await _apiService.post(
        AppEndpoints.signupOtpSend,
        data: {'phone': phoneNumber, 'referralCode': referralCode, 'deviceId': deviceId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppSnackbar.success("Success", "OTP sent successfully");
        return response.data;
      }

      throw ApiException(message: response.data['message'] ?? 'Failed to send OTP', data: response.data);
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? 'Network error', data: e.response?.data);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> verifySignUpOtp({
    required String phone,
    required String otp,
    required String smsToken,
    required String name,
    String? email,
    String? dateOfBirth,
    required String deviceId,
    required String fcmToken,
    required bool marketingConsent,
    required String language,
    required String geoLocation,
    String? referralCode,
    String deviceModel = '',
    String platform = '',
    String appVersion = '',
    String country = '',
    String state = '',
    String city = '',
  }) async {
    try {
      final Map<String, dynamic> data = {
        "phone": phone,
        "otp": otp,
        "name": name,
        "referralCode": referralCode,
        "deviceId": deviceId,
        "fcmToken": fcmToken,
        "consentVersion": "1.0",
        "marketingConsent": marketingConsent,
        "language": language,
        "geoLocation": geoLocation,
        "deviceModel": deviceModel,
        "platform": platform,
        "appVersion": appVersion,
        "country": country,
        "state": state,
        "city": city,
      };

      if (email != null && email.isNotEmpty) {
        data["email"] = email;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        data["dateOfBirth"] = dateOfBirth;
      }

      final response = await _apiService.post(AppEndpoints.signupComplete, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          await SecureStorageService.saveResponseData(response.data);
          return response.data['data'];
        } else {
          throw ApiException(message: response.data['message'] ?? 'Verification failed', data: response.data);
        }
      } else {
        throw ApiException(message: response.data['message'] ?? 'Verification failed', data: response.data);
      }
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? 'Network error', data: e.response?.data);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> signUpOauth(
    final String idToken, {
    String? phone,
    String? email,
    String? name,
    bool marketingConsent = false,
  }) async {
    try {
      print('OAuth Response: $idToken');
      final response = await _apiService.post(
        AppEndpoints.oAuth,
        data: {
          "marketingConsent": marketingConsent,
          "idToken": idToken,
          "consentVersion": "1.0",
          "deviceId": await AppConstants.getDeviceId(),
          if (phone != null && phone.isNotEmpty) "phone": phone,
          if (email != null && email.isNotEmpty) "email": email,
          if (name != null && name.isNotEmpty) "name": name,
        },
        requiresToken: true,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Google Sign-In failed',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> logoutOtherDevices() async {
    try {
      final response = await _apiService.post(AppEndpoints.logoutOtherDevices, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to log out other devices',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> getLockStatus(String phone) async {
    try {
      final response = await _apiService.post(AppEndpoints.lockStatus, data: {'phone': phone}, requiresToken: false);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        final d = response.data['data'];
        return d is Map ? Map<String, dynamic>.from(d) : {};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveDevices() async {
    try {
      final response = await _apiService.get(AppEndpoints.sessionDevices, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'];
        return list is List ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      }
      throw ApiException(
        message: response.data['message'] ?? 'Failed to fetch devices',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> updateFcmToken(final String fcmToken) async {
    try {
      final response = await _apiService.patch(
        AppEndpoints.updateFcmToken,
        data: {"fcmToken": fcmToken},
        requiresToken: true,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(
        message: response.data['message'] ?? 'Failed to update FCM token',
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e, s) {
      print('fcm error $e $s');
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await updateFcmToken(token);
    } catch (e) {
      debugPrint('FCM sync skipped: $e');
    }
  }

  static bool _fcmRefreshBound = false;
  void listenFcmRefresh() {
    if (_fcmRefreshBound) return;
    _fcmRefreshBound = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      try {
        await updateFcmToken(token);
      } catch (e) {
        debugPrint('FCM refresh push skipped: $e');
      }
    });
  }

  Future<String> validateRefferal(final String referralCode) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.validateReferral,
        data: {"code": referralCode},
        requiresToken: false,
      );

      return response.data['data']['name'] as String? ?? 'Referral valid';
    } on DioException catch (e) {
      final String message = e.response?.data['error']['message'] as String? ?? 'Invalid referral code';

      throw ApiException(message: message);
    }
  }

  Future<Map<String, dynamic>?> sendLoginOtp(final String phoneNumber) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.loginOtpSend,
        data: {'phone': phoneNumber},
        requiresToken: false,
      );
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return response.data;
        } else {
          throw ApiException(message: response.data['message'] ?? 'Failed to send OTP', data: response.data);
        }
      } else {
        throw ApiException(message: response.data['message'] ?? 'Network error', data: response.data);
      }
    } on DioException catch (e) {
      final Map<String, dynamic>? data = e.response?.data as Map<String, dynamic>?;
      final String message = data?['error']?['message'] as String? ?? data?['message'] as String? ?? 'Network error';
      throw ApiException(message: message, data: data);
    }
  }

  Future<Map<String, dynamic>?> verifyLoginOtp({
    required final String phone,
    required final String otp,
    required final String geoLocation,
    String fcmToken = '',
    String deviceModel = '',
    String platform = '',
    String appVersion = '',
    String country = '',
    String state = '',
    String city = '',
  }) async {
    try {
      String deviceId = await AppConstants.getDeviceId();
      final response = await _apiService.post(
        AppEndpoints.loginOtpVerify,
        data: {
          "phone": phone,
          "otp": otp,
          "deviceId": deviceId,
          "geoLocation": geoLocation,
          "fcmToken": fcmToken,
          "deviceModel": deviceModel,
          "platform": platform,
          "appVersion": appVersion,
          "country": country,
          "state": state,
          "city": city,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          await SecureStorageService.saveResponseData(response.data);
          return response.data['data'];
        } else {
          throw ApiException(message: response.data['message'] ?? 'Verification failed', data: response.data);
        }
      } else {
        throw ApiException(message: response.data['message'] ?? 'Verification failed', data: response.data);
      }
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? 'Network error', data: e.response?.data);
    }
  }
}
