import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';

class PaymentRepository {
  final ApiService _apiService = Get.find<ApiService>();
  Future<Map<String, dynamic>?> validatePromo({required String code, required String bookingId}) async {
    try {
      final response = await _apiService.post(AppEndpoints.validatePromo(bookingId), data: {'code': code});
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(message: response.data['message'] ?? 'Invalid promo code');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> applyPromo({required String code, required String bookingId}) async {
    try {
      final response = await _apiService.post(AppEndpoints.applyPromo(bookingId), data: {'code': code});
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(message: response.data['message'] ?? 'Invalid promo code');
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? 'Could not apply promo code', data: e.response?.data);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> removePromo({required String bookingId}) async {
    try {
      final response = await _apiService.delete(AppEndpoints.removePromo(bookingId));
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(message: response.data['message'] ?? 'Could not remove promo code');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>?> createTripPayment(
    String bookingId, {
    required String paymentMethod,
    String? promoCode,
    double? walletAmount,
  }) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.createTripPayment(bookingId),
        data: {
          'paymentMethod': paymentMethod,
          if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
          if (walletAmount != null && walletAmount > 0) 'walletAmount': walletAmount,
        },
        headers: {'Idempotency-Key': 'pay-$bookingId-$paymentMethod'},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to create payment');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Failed to create payment');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> failTransaction(String razorpayId) async {
    if (razorpayId.isEmpty) return;
    try {
      await _apiService.patch(AppEndpoints.failTransaction(razorpayId));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getCustomerWallet() async {
    try {
      final response = await _apiService.get(AppEndpoints.customerWallet);
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return response.data;
        } else {
          throw ApiException(message: response.data['message'] ?? 'Failed to get wallet');
        }
      } else {
        throw ApiException(message: response.data['message'] ?? 'Failed to get wallet');
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createWalletRecharge({required double amount}) async {
    try {
      final response = await _apiService.post(AppEndpoints.customerWalletAddMoney, data: {'amount': amount});

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(message: response.data['message'] ?? 'Failed to create recharge order');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> requestWalletWithdrawal({
    required double amount,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
  }) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.customerWalletWithdraw,
        requiresToken: true,
        data: {'amount': amount, 'bankAccountNumber': accountNumber, 'bankIfsc': ifscCode, 'bankName': bankName},
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data;
      }

      throw ApiException(message: response.data['message'] ?? 'Failed to request withdrawal');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    }
  }
}
