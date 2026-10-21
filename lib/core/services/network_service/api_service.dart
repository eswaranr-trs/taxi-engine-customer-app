import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:get/get.dart' hide Response;
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/controllers/trip_state_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/controllers/my_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';
import 'package:orange_taxi_customer_app/features/main/profile/controllers/profile_controller.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiService {
  late final Dio _dio;
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
      ),
    );

    if (kDebugMode || kProfileMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final bool requiresToken = options.extra['requiresToken'] == true;

          if (requiresToken) {
            final token = await SecureStorageService.getAuthToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            options.extra['sentWithToken'] = token ?? '';
          }
          handler.next(options);
        },

        onResponse: (response, handler) {
          if (Get.isRegistered<ConnectivityService>()) {
            Get.find<ConnectivityService>().reportServerUp();
          }
          handler.next(response);
        },

        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final int? status = error.response?.statusCode;
          if (status != null) {
            if (status >= 500 && status < 600) {
              if (Get.isRegistered<ConnectivityService>()) {
                Get.find<ConnectivityService>().verifyServerDown();
              }
            } else {
              if (Get.isRegistered<ConnectivityService>()) {
                Get.find<ConnectivityService>().reportServerUp();
              }
            }
          }

          _reportNetworkFault(error);

          if (status == 404) _handleMissingTrip(error);

          final bool requiresToken = error.requestOptions.extra['requiresToken'] == true;
          if (error.response?.statusCode == 401 && requiresToken) {
            final String sentWith = (error.requestOptions.extra['sentWithToken'] ?? '').toString();
            final String? current = await SecureStorageService.getAuthToken();
            if (sentWith == (current ?? '')) {
              await forceLogout();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresToken = true,
    ResponseType? responseType,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'requiresToken': requiresToken}, responseType: responseType),
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    bool requiresToken = true,
    Map<String, dynamic>? headers,
  }) async {
    return _dio.post(
      path,
      data: data,
      options: Options(extra: {'requiresToken': requiresToken}, headers: headers),
    );
  }

  Future<Response<dynamic>> put(String path, {dynamic data, bool requiresToken = true}) async {
    return _dio.put(
      path,
      data: data,
      options: Options(extra: {'requiresToken': requiresToken}),
    );
  }

  Future<Response<dynamic>> patch(String path, {dynamic data, bool requiresToken = true}) async {
    return _dio.patch(
      path,
      data: data,
      options: Options(extra: {'requiresToken': requiresToken}),
    );
  }

  Future<Response<dynamic>> delete(String path, {dynamic data, bool requiresToken = true}) async {
    return _dio.delete(
      path,
      data: data,
      options: Options(extra: {'requiresToken': requiresToken}),
    );
  }

  Future<void> refreshToken() async {
    final String? refreshToken = await SecureStorageService.getRefreshToken();

    if (refreshToken == null) {
      throw ApiException(message: 'Refresh token missing');
    }

    final Response<dynamic> response = await _dio.post(
      AppEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'requiresToken': false}),
    );

    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    final String newAccessToken = data['accessToken'] as String;
    await SecureStorageService.saveAuthToken(newAccessToken);
  }

  Future<Response<dynamic>> retryRequest(RequestOptions requestOptions) async {
    final String? accessToken = await SecureStorageService.getAuthToken();
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(method: requestOptions.method, headers: requestOptions.headers, extra: requestOptions.extra),
    );
  }

  /// Single place that turns transport-level failures into user feedback.
  /// Everything here routes through [AppSnackbar.network], which collapses
  /// simultaneous failures into one message and mutes per-call error snackbars
  /// for a few seconds afterwards.
  void _reportNetworkFault(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        AppSnackbar.network(
          'Connection Timed Out',
          'The server is taking too long to respond. Please try again.',
          icon: Icons.access_time_rounded,
        );
        return;
      case DioExceptionType.connectionError:
        AppSnackbar.network('Network Error', 'Could not reach the server. Check your connection and try again.');
        return;
      default:
        if (error.error is SocketException) {
          AppSnackbar.network('Network Error', 'Could not reach the server. Check your connection and try again.');
        }
        return;
    }
  }

  static DateTime? _lastMissingTripAt;

  void _handleMissingTrip(DioException error) {
    final data = error.response?.data;
    final String message = (data is Map ? (data['message'] ?? '') : '').toString();
    if (!message.toLowerCase().contains('trip not found')) return;
    final now = DateTime.now();
    if (_lastMissingTripAt != null && now.difference(_lastMissingTripAt!) < const Duration(seconds: 3)) return;
    _lastMissingTripAt = now;

    print('[api] 404 "$message" on ${error.requestOptions.path} — clearing trip and going home');

    String bookingId = '';
    if (Get.isRegistered<TripStateService>()) {
      final tripState = Get.find<TripStateService>();
      bookingId = tripState.selectedBookingId.value;

      final String fromPath = _bookingIdFromPath(error.requestOptions.path, tripState.activeTrips.keys);
      if (fromPath.isNotEmpty) bookingId = fromPath;

      if (bookingId.isNotEmpty) tripState.removeTrip(bookingId);
    }
    if (bookingId.isNotEmpty && Get.isRegistered<ActiveTripsController>()) {
      Get.find<ActiveTripsController>().markCancelled(bookingId);
    }
    if (Get.isRegistered<ActiveTripsController>()) {
      Get.find<ActiveTripsController>().fetchActiveTrips();
    }

    if (!AppRoutes.tripFlowRoutes.contains(Get.currentRoute)) return;
    AppSnackbar.error('Trip unavailable', message);
    Get.until((route) => route.settings.name == AppRoutes.home || route.isFirst);
  }

  String _bookingIdFromPath(String path, Iterable<String> knownIds) {
    for (final id in knownIds) {
      if (id.isNotEmpty && id != 'pending_booking' && path.contains(id)) return id;
    }
    return '';
  }

  static bool _loggingOut = false;

  Future<void> forceLogout() async {
    if (_loggingOut) return;
    if (!await LocalStorageService.isLoggedIn()) return;
    _loggingOut = true;
    try {
      if (Get.isRegistered<TripStateService>()) {
        Get.find<TripStateService>().resetToDummy();
      }
      SocketService().disconnect();
      await LocalStorageService.clear();
      await SecureStorageService.clear();
      for (final del in <void Function()>[
        () => Get.delete<ActiveTripsController>(force: true),
        () => Get.delete<MyTripsController>(force: true),
        () => Get.delete<SavedAddressesController>(force: true),
        () => Get.delete<TripStateController>(force: true),
        () => Get.delete<TripController>(force: true),
        () => Get.delete<HomeController>(force: true),
        () => Get.delete<ProfileController>(force: true),
      ]) {
        try {
          del();
        } catch (_) {}
      }

      AppSnackbar.error('Session Expired', 'Your session has expired. Please log in again.');
      await Get.offAllNamed(AppRoutes.login);

      Future.delayed(const Duration(milliseconds: 500), () async {
        if (await LocalStorageService.isLoggedIn()) return;
        if (Get.currentRoute != AppRoutes.login) {
          await Get.offAllNamed(AppRoutes.login);
        }
      });
    } finally {
      Future.delayed(const Duration(seconds: 2), () => _loggingOut = false);
    }
  }
}
