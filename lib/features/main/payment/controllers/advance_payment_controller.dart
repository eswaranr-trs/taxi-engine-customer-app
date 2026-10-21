import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/payment_api/payment_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/payment/views/advance_payment_success_screen.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class AdvancePaymentController extends GetxController {
  final TripsRepository _tripsRepo = TripsRepository();
  final AuthRepository _authRepo = AuthRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  final RxList<int> percentages = <int>[].obs;
  final RxInt selectedPercent = 0.obs;
  final RxString method = 'online'.obs;
  final RxDouble walletBalance = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPaying = false.obs;

  double totalFare = 0;
  String bookingId = '';
  VoidCallback? onPaid;
  bool isScheduled = false;

  late Razorpay _razorpay;
  String? _razorpayKey;

  bool awaitingGateway = false;
  Completer<void>? _gateway;
  String _lastRazorpayId = '';
  Future<void> get gatewayDone => _gateway?.future ?? Future<void>.value();

  void _completeGateway() {
    awaitingGateway = false;
    if (_gateway != null && !_gateway!.isCompleted) _gateway!.complete();
  }

  double get amount => (totalFare * selectedPercent.value) / 100;

  void configure({
    required String bookingId,
    required double totalFare,
    VoidCallback? onPaid,
    bool isScheduled = false,
  }) {
    this.bookingId = bookingId;
    this.totalFare = totalFare;
    this.onPaid = onPaid;
    this.isScheduled = isScheduled;
    if (isScheduled && Get.isRegistered<TripStateService>()) {
      Get.find<TripStateService>().muteAutoNav(bookingId);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternal);

    ever(selectedPercent, (_) => _ensureAffordableMethod());
    ever(walletBalance, (_) => _ensureAffordableMethod());

    _load();
  }

  void _ensureAffordableMethod() {
    if (method.value == 'wallet' && walletBalance.value < amount) {
      method.value = 'online';
    }
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final list = await _authRepo.getConfigList('bookingPaymentPercentages');
      final parsed = list.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList()..sort();
      percentages.assignAll(parsed);
      if (percentages.isNotEmpty) selectedPercent.value = percentages.first;

      final w = await _paymentRepo.getCustomerWallet();
      if (w != null && w['success'] == true) {
        walletBalance.value = double.tryParse(w['data']['balance'].toString()) ?? 0.0;
      }
      _razorpayKey ??= await _authRepo.getConfigValue('razorpayKey');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  Future<void> pay() async {
    if (isPaying.value) return;
    if (selectedPercent.value <= 0) {
      AppSnackbar.warning('Select amount', 'Choose an advance percentage first.');
      return;
    }
    if (method.value == 'wallet' && walletBalance.value < amount) {
      AppSnackbar.warning('Insufficient Balance', 'Your wallet balance is low for this advance.');
      return;
    }

    try {
      isPaying.value = true;
      final String apiMethod = method.value == 'wallet' ? 'wallet' : 'online';

      final res = await _tripsRepo.createAdvancePayment(
        bookingId,
        percentage: selectedPercent.value,
        method: apiMethod,
      );
      final data = res?['data'] as Map<String, dynamic>?;

      if (apiMethod == 'wallet') {
        AppSnackbar.success('Advance Paid', res?['message']?.toString() ?? 'Advance payment successful');
        _finish();
        return;
      }

      _razorpayKey ??= await _authRepo.getConfigValue('razorpayKey');
      if (_razorpayKey == null || _razorpayKey!.isEmpty) {
        AppSnackbar.error('Error', 'Payment config unavailable');
        return;
      }

      final orderId = (data?['razorpayOrderId'] ?? data?['orderId'] ?? data?['order_id'] ?? data?['id'])?.toString();
      final orderAmount = data?['amount'];

      final options = {
        'key': _razorpayKey!,
        'amount': orderAmount ?? (amount * 100).toInt(),
        'currency': data?['currency']?.toString() ?? 'INR',
        'name': 'Orange Taxi',
        'description': 'Advance Payment',
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        'notes': {'bookingId': bookingId},
      };

      _gateway = Completer<void>();
      awaitingGateway = true;
      if (Get.isBottomSheetOpen ?? false) Get.back();

      _lastRazorpayId = orderId ?? '';
      _razorpay.open(options);
    } on ApiException catch (e) {
      AppSnackbar.error('Advance Payment', e.message);
      _completeGateway();
    } catch (_) {
      AppSnackbar.error('Advance Payment', 'Something went wrong');
      _completeGateway();
    } finally {
      if (!awaitingGateway) isPaying.value = false;
    }
  }

  void _onSuccess(PaymentSuccessResponse response) {
    isPaying.value = false;
    AppSnackbar.success('Advance Paid', 'Payment successful');
    _finish();
  }

  void _onError(PaymentFailureResponse response) {
    isPaying.value = false;
    _paymentRepo.failTransaction(_lastRazorpayId);
    _lastRazorpayId = '';
    AppSnackbar.error('Payment Failed', 'Advance payment was not completed. Please try again.');
    _completeGateway();
  }

  void _onExternal(ExternalWalletResponse response) {
    isPaying.value = false;
    _completeGateway();
  }

  void _finish() {
    if (!awaitingGateway && (Get.isBottomSheetOpen ?? false)) Get.back();
    final double paidAmount = amount;
    final VoidCallback? cb = onPaid;
    final bool scheduled = isScheduled;

    final TripStateService? tss = Get.isRegistered<TripStateService>() ? Get.find<TripStateService>() : null;

    if (scheduled) tss?.suppressAutoNav = true;

    Get.bottomSheet(
      AdvancePaymentSuccessScreen(
        amount: paidAmount,
        onDone: () {
          cb?.call();
          if (scheduled) tss?.releaseAutoNav();
        },
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.transparent,
    );
    _completeGateway();
  }
}
