import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/data/repositories/enquiry_api/enquiry_repository.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/controller/wallet_controller.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/payment_api/payment_repository.dart';

class CancelRideBottomSheet extends StatefulWidget {
  final VoidCallback? onCancelComplete;
  final String? bookingId;
  const CancelRideBottomSheet({super.key, this.onCancelComplete, this.bookingId});

  @override
  State<CancelRideBottomSheet> createState() => _CancelRideBottomSheetState();
}

class _CancelRideBottomSheetState extends State<CancelRideBottomSheet> {
  int _currentStep = 0;
  bool _submitting = false;
  String _selectedReason = 'I booked by mistake';
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _reasons = ['I booked by mistake', 'My plans have changed', 'Found a better option', 'Others'];

  late Razorpay _razorpay;
  String? _razorpayKey;
  final AuthRepository _authRepository = AuthRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  String _lastRazorpayId = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchRazorpayKey();
  }

  Future<void> _fetchRazorpayKey() async {
    _razorpayKey = await _authRepository.getConfigValue('razorpayKey');
  }

  @override
  void dispose() {
    _razorpay.clear();
    if (_lastRazorpayId.isNotEmpty) {
      _paymentRepository.failTransaction(_lastRazorpayId);
    }
    if (WalletController.pendingAfterTopUp == _resumeCancelAfterTopUp) WalletController.pendingAfterTopUp = null;
    _reasonController.dispose();
    super.dispose();
  }

  void _resumeCancelAfterTopUp() {
    if (mounted) _onSubmitReason();
  }

  void _onCancelConfirmed() {
    setState(() {
      _currentStep = 1;
    });
  }

  final EnquiryRepository enquiryRepository = EnquiryRepository();

  void _onSubmitReason() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final tripStateService = Get.find<TripStateService>();
    final String bookingId = widget.bookingId ?? tripStateService.selectedTrip?.bookingId ?? '';
    final String reason = _selectedReason == 'Others' ? _reasonController.text.trim() : _selectedReason;

    try {
      final response = await enquiryRepository.cancelTrip(tripId: bookingId, reason: reason);

      if (response != null && response['success'] == true) {
        tripStateService.suppressAutoNavFor(const Duration(seconds: 90));
        tripStateService.clearTripDetails();

        if (Get.isRegistered<ActiveTripsController>()) {
          final atc = Get.find<ActiveTripsController>();
          atc.markCancelled(bookingId);
          atc.fetchActiveTrips().whenComplete(tripStateService.releaseAutoNav);
        } else {
          tripStateService.releaseAutoNav();
        }

        AppSnackbar.success('Trip Cancelled', 'Your trip has been cancelled');
        await Get.offAll(() => const CancellationSuccessScreen());
      } else {
        setState(() => _submitting = false);
        AppSnackbar.error('Cancellation Failed', response?['message']?.toString() ?? 'Could not cancel the trip');
      }
    } on ApiException catch (e) {
      setState(() => _submitting = false);

      if (_isInsufficientBalance(e)) {
        final Map<String, dynamic> responseData = e.data is Map ? Map<String, dynamic>.from(e.data) : {};

        final Map<String, dynamic> paymentData = responseData['data'] is Map
            ? Map<String, dynamic>.from(responseData['data'])
            : responseData;

        _showInsufficientBalanceDialog(e.message, paymentData);
      } else {
        AppSnackbar.error('Cancellation Failed', e.message);
      }
    } catch (e) {
      setState(() => _submitting = false);
      AppSnackbar.error('Cancellation Failed', 'Could not cancel the trip');
    }
  }

  bool _isInsufficientBalance(ApiException e) {
    final String message = e.message.toLowerCase();

    final String code =
        (e.data is Map ? (e.data['code'] ?? e.data['errorCode']) : null)?.toString().toLowerCase() ?? '';

    return e.statusCode == 402 ||
        message.contains('insufficient') ||
        message.contains('low balance') ||
        (message.contains('wallet') && message.contains('balance')) ||
        code.contains('insufficient');
  }

  void _showInsufficientBalanceDialog(String message, Map<String, dynamic> data) {
    final String? orderId = (data['razorpayOrderId'] ?? data['orderId'] ?? data['order_id'] ?? data['id'])?.toString();

    final int amount =
        int.tryParse(data['amount']?.toString() ?? '0') ??
        (double.tryParse(data['amount']?.toString() ?? '0') ?? 0).toInt();

    final String currency = data['currency']?.toString() ?? 'INR';

    Get.dialog(
      barrierDismissible: false,
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: AppColors.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 28),
              ),

              16.height,

              const CustomText(text: 'Payment Required', fontSize: 17, fontWeight: FontWeight.bold),

              8.height,

              CustomText(text: message, fontSize: 13, color: AppColors.grey600, textAlign: TextAlign.center),

              18.height,

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CustomText(text: 'Cancel', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  12.width,

                  // Pay
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (orderId == null || orderId.isEmpty || amount <= 0) {
                          Get.back();
                          AppSnackbar.error('Payment Error', 'Unable to start payment. Please try again.');
                          return;
                        }

                        _lastRazorpayId = orderId;
                        Get.back();

                        _openRazorpayForCancellation(orderId: orderId, amount: amount, currency: currency);
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientButton,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CustomText(
                            text: 'Pay',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (orderId != null && orderId.isNotEmpty && _lastRazorpayId != orderId) {
        _paymentRepository.failTransaction(orderId);
      }
    });
  }

  void _openRazorpayForCancellation({required String orderId, required int amount, required String currency}) async {
    _razorpayKey ??= await _authRepository.getConfigValue('razorpayKey');
    if (_razorpayKey == null || _razorpayKey!.isEmpty) {
      AppSnackbar.error('Payment Error', 'Payment config unavailable');
      return;
    }

    _lastRazorpayId = orderId;

    final options = {
      'key': _razorpayKey!,
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'name': 'Orange Taxi',
      'description': 'Trip Cancellation Fee',
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      AppSnackbar.error('Payment Error', 'Failed to open payment gateway');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _lastRazorpayId = '';
    _onSubmitReason();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_lastRazorpayId.isNotEmpty) {
      _paymentRepository.failTransaction(_lastRazorpayId);
      _lastRazorpayId = '';
    }
    AppSnackbar.error('Payment Failed', response.message ?? 'Payment cancelled');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [if (_currentStep == 0) _buildConfirmationStep() else _buildReasonStep()],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 24),
            const CustomText(text: 'Cancel Booking?', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.red),
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.close, color: AppColors.grey, size: 20),
            ),
          ],
        ),
        24.height,
        const CustomText(
          text: 'Are you sure you want to cancel the\ntrip ?',
          fontSize: 14,
          color: AppColors.black87,
          textAlign: TextAlign.center,
        ),
        32.height,
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CustomText(
                      text: "No, Don't Cancel",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black87,
                    ),
                  ),
                ),
              ),
            ),
            16.width,
            Expanded(
              child: GestureDetector(
                onTap: _onCancelConfirmed,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: CustomText(
                      text: "Cancel",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        16.height,
      ],
    );
  }

  Widget _buildReasonStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 24),
            const CustomText(
              text: 'Cancellation Reason?',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.close, color: AppColors.grey, size: 20),
            ),
          ],
        ),
        16.height,
        const Center(
          child: CustomText(text: 'Why are you cancelling this trip?', fontSize: 14, color: AppColors.grey),
        ),
        24.height,
        ..._reasons.map((reason) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedReason = reason;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedReason == reason ? AppColors.primary : AppColors.grey,
                        width: 2,
                      ),
                    ),
                    child: _selectedReason == reason
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  12.width,
                  CustomText(text: reason, fontSize: 14, color: AppColors.black87),
                ],
              ),
            ),
          );
        }),
        if (_selectedReason == 'Others')
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your reason here...',
                  hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14, fontFamily: 'Poppins'),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        24.height,
        GestureDetector(
          onTap: _submitting ? null : _onSubmitReason,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              // color: _submitting ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
              gradient: AppColors.gradientButton,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _submitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        ),
                        10.width,
                        const CustomText(
                          text: 'Submitting...',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ],
                    )
                  : const CustomText(text: 'Submit', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white),
            ),
          ),
        ),
        16.height,
      ],
    );
  }
}

class CancellationSuccessScreen extends StatelessWidget {
  const CancellationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.black, size: 18),
              onPressed: () {
                if (Get.isRegistered<HomeController>()) Get.find<HomeController>().resetTripSelection();
                Get.offAllNamed(AppRoutes.home);
              },
            ),
          ),
        ),
        title: const CustomText(
          text: 'Trip Cancellation',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                  boxShadow: [BoxShadow(color: AppColors.red.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 10)],
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 40),
              ),
              32.height,
              const CustomText(
                text: 'Cancellation Successful',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
              16.height,
              const CustomText(
                text: 'The trip has been cancelled successfully.\nAny applicable refund will be processed\nsoon',
                fontSize: 14,
                color: AppColors.grey,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (Get.isRegistered<HomeController>()) Get.find<HomeController>().resetTripSelection();
                  Get.offAllNamed(AppRoutes.home);
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: CustomText(
                      text: 'Back to Home',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              16.height,
            ],
          ),
        ),
      ),
    );
  }
}
