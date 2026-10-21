import 'dart:io';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDio(DioException e, {String fallback = 'Something went wrong'}) {
    if (e.response == null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.error is SocketException)) {
      return OfflineException();
    }

    final data = e.response?.data;
    final int? code = e.response?.statusCode;

    String? serverMsg;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m != null && m.toString().trim().isNotEmpty) serverMsg = m.toString();
    }

    final String message = serverMsg ?? (code != null ? 'Server error ($code). Please try again.' : fallback);
    return ApiException(message: message, statusCode: code, data: data);
  }

  bool get isOffline => this is OfflineException;

  @override
  String toString() {
    return message;
  }
}

class OfflineException extends ApiException {
  OfflineException({super.message = 'Something went wrong. Please try again later.'});
}
