import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/payment_api/payment_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';

class PaymentController extends GetxController {
  RxString selectedPaymentMethod = 'upi'.obs;
  var isPhoneConfirmed = false.obs;

  var selectedBookingFor = 'myself'.obs;
  var walletBalance = 0.0.obs;
  var phoneNumberController = TextEditingController();
  var nameController = TextEditingController();
  var isOthersSelected = false.obs;

  final PaymentRepository _paymentRepository = PaymentRepository();
  final TripsRepository _tripsRepository = TripsRepository();

  final RxInt tipAmount = 0.obs;
  final RxInt pendingTip = 0.obs;
  final TextEditingController tipController = TextEditingController();
  final RxBool isApplyingTip = false.obs;
  final RxBool tipDismissed = false.obs;
  final RxBool showTipField = false.obs;

  int get _effectivePendingTip {
    final custom = int.tryParse(tipController.text.trim());
    if (custom != null && custom > 0) return custom;
    return pendingTip.value;
  }

  Future<void> applyTip() async {
    if (isApplyingTip.value) return;
    final ts = Get.find<TripStateService>();
    final bookingId = ts.selectedTrip?.bookingId ?? '';
    if (bookingId.isEmpty) {
      AppSnackbar.error('Tip', 'Trip not found');
      return;
    }
    final int amount = _effectivePendingTip;
    isApplyingTip.value = true;
    try {
      await _tripsRepository.addTip(bookingId, amount);
      await ts.refreshTripFare(bookingId);
      tipAmount.value = amount;
      showTipField.value = false;
      AppSnackbar.success('Tip', amount > 0 ? 'Tip of ₹$amount added' : 'Tip removed');
    } catch (e) {
      AppSnackbar.error('Tip', e is ApiException ? e.message : 'Could not add tip');
    } finally {
      isApplyingTip.value = false;
    }
  }

  Future<void> removeTip() async {
    if (isApplyingTip.value) return;
    final ts = Get.find<TripStateService>();
    final bookingId = ts.selectedTrip?.bookingId ?? '';
    if (bookingId.isEmpty) {
      AppSnackbar.error('Tip', 'Trip not found');
      return;
    }
    isApplyingTip.value = true;
    try {
      await _tripsRepository.removeTip(bookingId);
      await ts.refreshTripFare(bookingId);
      tipAmount.value = 0;
      pendingTip.value = 0;
      tipController.clear();
      showTipField.value = false;
      AppSnackbar.success('Tip', 'Tip removed');
    } catch (e) {
      AppSnackbar.error('Tip', e is ApiException ? e.message : 'Could not remove tip');
    } finally {
      isApplyingTip.value = false;
    }
  }

  bool get isWalletUsable => walletBalance.value > 0;

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
    paymentError.value = null;
  }

  void selectBookingFor(String who) {
    selectedBookingFor.value = who;
  }

  Future<void> getCustomerWallet() async {
    try {
      final result = await _paymentRepository.getCustomerWallet();

      if (result != null && result['success'] == true) {
        walletBalance.value = double.tryParse(result['data']['balance'].toString()) ?? 0.0;
        if (selectedPaymentMethod.value == 'wallet' && !isWalletUsable) {
          selectedPaymentMethod.value = 'upi';
        }
      }
    } catch (e) {
      AppSnackbar.error('Error', e.toString());
    }
  }

  void confirmPhone() {
    final phone = phoneNumberController.text.trim();

    if (phone.isEmpty) {
      AppSnackbar.error('Error', 'Please enter phone number');
      return;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      AppSnackbar.error('Error', 'Enter valid 10-digit number');
      return;
    }

    isPhoneConfirmed.value = true;
    AppSnackbar.success('Success', 'Phone number confirmed');
  }

  final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();

  Future<void> pickContact() async {
    try {
      final status = await Permission.contacts.request();

      if (!status.isGranted) return;
      final Contact? contact = await contactPicker.selectContact();

      if (contact != null) {
        String phone = contact.phoneNumbers?.first ?? '';
        phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

        if (phone.length > 10) {
          phone = phone.substring(phone.length - 10);
        }
        phoneNumberController.text = phone;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  late Razorpay razorpay;
  final AuthRepository _authRepository = AuthRepository();
  String? _razorpayKey;

  final isLoading = false.obs;

  final promoController = TextEditingController();
  final RxnString appliedPromo = RxnString();
  final RxDouble promoDiscount = 0.0.obs;
  final RxnString promoError = RxnString();
  final RxBool isApplyingPromo = false.obs;
  final RxBool showPromoField = false.obs;
  final RxBool showFareBreakdown = false.obs;
  final RxBool isRefreshingFare = false.obs;

  double payableAmount(double baseTotal) => baseTotal < 0 ? 0 : baseTotal;

  final RxBool awaitingCash = false.obs;
  final RxnString cashBookingId = RxnString();
  final RxnString cashWaitingNotice = RxnString();
  final RxnString paymentError = RxnString();

  bool isAwaitingCashFor(String? bookingId) =>
      awaitingCash.value && bookingId != null && bookingId.isNotEmpty && cashBookingId.value == bookingId;
  final RxBool useWallet = false.obs;
  final RxnDouble walletApplied = RxnDouble();
  final RxBool showWalletOther = false.obs;
  final walletController = TextEditingController();

  double walletCap(double payable) =>
      (walletBalance.value <= 0 || payable <= 0) ? 0 : walletBalance.value.clamp(0, payable);

  double walletCreditFor(double payable) {
    if (!useWallet.value) return 0;
    final double cap = walletCap(payable);
    return (walletApplied.value ?? cap).clamp(0, cap);
  }

  double remainingAfterWallet(double payable) =>
      (payable - walletCreditFor(payable)).clamp(0, double.infinity).toDouble();

  void setWalletCredit(double amount) {
    walletApplied.value = amount;
    showWalletOther.value = false;
    walletController.clear();
  }

  Future<void> applyPromo(double baseTotal) async {
    final code = promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      promoError.value = 'Enter a valid promo code';
      return;
    }
    if (isApplyingPromo.value) return;
    final bookingId = Get.find<TripStateService>().selectedTrip?.bookingId ?? '';
    if (bookingId.isEmpty) {
      promoError.value = 'Booking not found';
      return;
    }
    try {
      isApplyingPromo.value = true;
      promoError.value = null;
      final res = await _paymentRepository.applyPromo(code: code, bookingId: bookingId);
      final data = res?['data'];
      final disc =
          double.tryParse((data is Map ? (data['discountAmount'] ?? data['discount']) : null)?.toString() ?? '') ?? 0.0;
      if (disc <= 0) {
        promoError.value = res?['message']?.toString() ?? 'Code not applicable to this trip';
        return;
      }
      appliedPromo.value = code;
      promoDiscount.value = disc > baseTotal ? baseTotal : disc;
      Get.find<TripStateService>().setPromo(bookingId: bookingId, code: code, discount: promoDiscount.value);
      await refreshFare();
      AppSnackbar.success('Promo Applied', 'You saved ₹${promoDiscount.value.toStringAsFixed(0)}');
    } catch (e) {
      appliedPromo.value = null;
      promoDiscount.value = 0.0;
      promoError.value = e is ApiException ? e.message : 'Could not apply promo code';
    } finally {
      isApplyingPromo.value = false;
    }
  }

  void clearPromo() async {
    final bookingId = Get.find<TripStateService>().selectedTrip?.bookingId ?? '';
    if (bookingId.isNotEmpty) {
      try {
        await _paymentRepository.removePromo(bookingId: bookingId);
      } catch (_) {}
    }
    appliedPromo.value = null;
    promoDiscount.value = 0.0;
    promoError.value = null;
    promoController.clear();
    Get.find<TripStateService>().clearPromo();
    await refreshFare();
  }

  Future<void> refreshFare() async {
    final ts = Get.find<TripStateService>();
    final String bookingId = ts.selectedTrip?.bookingId ?? '';
    if (bookingId.isEmpty) return;

    isRefreshingFare.value = true;
    try {
      await ts.refreshTripFare(bookingId);
    } finally {
      isRefreshingFare.value = false;
    }

    if (ts.promoBookingId == bookingId && (ts.promoCode?.isNotEmpty ?? false) && ts.promoDiscount > 0) {
      appliedPromo.value = ts.promoCode;
      promoDiscount.value = ts.promoDiscount;
    }

    final double total =
        ts.selectedTrip?.customerFinalAmount ??
        ts.selectedTrip?.tripCompletedFinalAmount ??
        ts.selectedTrip?.totalFare ??
        0;
    if (total > 0 && promoDiscount.value > total) {
      promoDiscount.value = total;
      ts.promoDiscount = total;
    }
  }

  @override
  void onInit() {
    super.onInit();

    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    _fetchRazorpayKey();
    getCustomerWallet();
    refreshFare();
  }

  Future<void> _fetchRazorpayKey() async {
    _razorpayKey = await _authRepository.getConfigValue('razorpayKey');
  }

  @override
  void onClose() {
    phoneNumberController.clear();
    phoneNumberController.dispose();
    promoController.dispose();
    tipController.dispose();
    walletController.dispose();
    razorpay.clear();
    super.onClose();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    isPhoneConfirmed.value = false;
    super.dispose();
  }

  String _lastRazorpayId = '';

  Future<void> startPayment({required double amount}) async {
    if (amount <= 0) {
      AppSnackbar.error('Error', 'Invalid payment amount');
      return;
    }
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      paymentError.value = null;
      cashWaitingNotice.value = null;

      final bookingId = Get.find<TripStateService>().selectedTrip?.bookingId ?? '';
      if (bookingId.isEmpty) {
        AppSnackbar.error('Error', 'Booking not found');
        return;
      }

      final paymentMethod = selectedPaymentMethod.value == 'online' ? 'upi' : selectedPaymentMethod.value;

      if (paymentMethod != 'upi' && paymentMethod != 'cash') {
        AppSnackbar.warning('Select Payment Method', 'Please choose Online Payment or Cash.');
        return;
      }

      final response = await _paymentRepository.createTripPayment(
        bookingId,
        paymentMethod: paymentMethod,
        promoCode: appliedPromo.value,
        walletAmount: walletCreditFor(payableAmount(amount)),
      );
      final data = response?['data'] as Map<String, dynamic>?;
      final String message = response?['message']?.toString() ?? '';
      debugPrint("Message $message");

      final tripState = Get.find<TripStateService>();
      tripState.lastPaidAmount = amount;
      tripState.lastPaymentBookingId = (data?['bookingId'] ?? bookingId).toString();
      tripState.socketPaymentMethod = TripStateService.paymentMethodLabel(selectedPaymentMethod.value);
      tripState.lastPaymentTxnId = (data?['receipt'] ?? data?['orderId'])?.toString();

      if (paymentMethod == 'cash') {
        cashBookingId.value = bookingId;
        awaitingCash.value = true;
        AppSnackbar.info('Cash Payment', message.isNotEmpty ? message : 'Pay the amount directly to your driver');
        return;
      }

      if (paymentMethod != 'upi') {
        tripState.lastPaymentDate = DateTime.now();
        if (message.isNotEmpty) AppSnackbar.success('Success', message);
        Get.offAllNamed(AppRoutes.paymentSuccess);
        return;
      }

      _razorpayKey ??= await _authRepository.getConfigValue('razorpayKey');
      if (_razorpayKey == null || _razorpayKey!.isEmpty) {
        AppSnackbar.error('Error', 'Payment config unavailable');
        return;
      }

      final orderId = (data?['orderId'] ?? data?['order_id'] ?? data?['id'])?.toString();
      final orderAmount = data?['amount'];

      final options = {
        'key': _razorpayKey!,
        'amount': orderAmount ?? (amount * 100).toInt(),
        'currency': data?['currency']?.toString() ?? 'INR',
        'name': 'Orange Taxi',
        'description': 'Ride Payment',
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        'notes': {'bookingId': bookingId},
      };

      _lastRazorpayId = orderId ?? '';
      _gatewayOpen = true;
      razorpay.open(options);
    } catch (e) {
      debugPrint('startPayment error: $e');
      final errorMsg = e is ApiException ? e.message : e.toString();

      if (selectedPaymentMethod.value == 'cash' && e is ApiException && e.statusCode == 400) {
        cashBookingId.value = Get.find<TripStateService>().selectedTrip?.bookingId ?? '';
        cashWaitingNotice.value = e.message;
        awaitingCash.value = true;
        return;
      }

      if (errorMsg.contains('payment status has not yet been confirmed')) {
        final bookingId = Get.find<TripStateService>().selectedTrip?.bookingId ?? '';
        cashBookingId.value = bookingId;
        awaitingCash.value = true;
        return;
      }

      paymentError.value = e is ApiException ? e.message : 'Failed to start payment';
    } finally {
      if (!_gatewayOpen) isLoading.value = false;
    }
  }

  bool _gatewayOpen = false;

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("SUCCESS ${response.paymentId}");

    final tripState = Get.find<TripStateService>();
    tripState.lastPaymentDate = DateTime.now();
    if (response.paymentId != null && response.paymentId!.isNotEmpty) {
      tripState.lastPaymentTxnId = response.paymentId;
    }

    _gatewayOpen = false;
    isLoading.value = false;
    _markTripPaid(tripState.lastPaymentBookingId ?? '');
    Get.offAllNamed(AppRoutes.paymentSuccess);
  }

  void _markTripPaid(String bookingId) {
    if (bookingId.isEmpty) return;
    Get.find<TripStateService>().clearPromo();
    Get.find<TripStateService>().clearTripIfPaid(bookingId, paymentStatus: 'paid');
    if (Get.isRegistered<ActiveTripsController>()) {
      Get.find<ActiveTripsController>().markPaid(bookingId);
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    debugPrint("ERROR ${response.code} ${response.message}");
    _gatewayOpen = false;
    isLoading.value = false;
    _paymentRepository.failTransaction(_lastRazorpayId);
    _lastRazorpayId = '';
    AppSnackbar.error('Payment Failed', 'Payment was not completed. Please try again.');
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("WALLET ${response.walletName}");
    _gatewayOpen = false;
    isLoading.value = false;
  }
}
