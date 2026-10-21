import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/invoice_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripStateService = Get.find<TripStateService>();
    final activeTrip = tripStateService.selectedTrip;

    final String transactionId = tripStateService.lastPaymentTxnId ?? '-';
    final String amountPaid = '₹${tripStateService.lastPaidAmount.toStringAsFixed(2)}';
    final String paymentMethod = tripStateService.socketPaymentMethod ?? 'Cash';
    final bool isCash = paymentMethod.toLowerCase().contains('cash');
    final String? bookingIdValue = tripStateService.lastPaymentBookingId ?? activeTrip?.bookingId;
    final String formattedDate = DateFormat(
      'MMM dd, yyyy, hh:mm a',
    ).format(tripStateService.lastPaymentDate ?? DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        surfaceTintColor: AppColors.transparent,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: const CustomText(
          text: 'Payment Status',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkSlate,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: 0.7,
                child: Lottie.asset('assets/lotties/success.json', height: 220, width: 220, repeat: false),
              ),
            ),

            Center(
              child: CustomText(
                text: 'Payment Successful',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.darkSlate,
              ),
            ),
            8.height,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CustomText(
                text: 'Your payment has been processed successfully. Thank you for riding with us!',
                fontSize: 14,
                color: AppColors.slate500,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
            32.height,
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    text: 'TRANSACTION DETAILS',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey400,
                  ),
                  16.height,
                  if (!isCash) ...[_buildDetailRow('Transaction ID', transactionId), 10.height],
                  _buildAmountRow('Amount Paid', amountPaid),
                  10.height,
                  _buildPaymentMethodRow('Payment Method', paymentMethod),
                  10.height,
                  _buildDetailRow('Date & Time', formattedDate),
                ],
              ),
            ),
            40.height,
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _downloadInvoice(bookingIdValue),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientButton,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CustomText(
                            text: 'View Invoice',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          10.width,
                          const Icon(Icons.receipt_long, color: AppColors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                12.width,
                Expanded(
                  child: GestureDetector(
                    onTap: () => _saveInvoice(bookingIdValue),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                        boxShadow: AppShadows.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(
                            text: 'Download Invoice',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                          ),
                          2.width,
                          const Icon(Icons.file_download_outlined, color: AppColors.darkSlate, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            12.height,
            GestureDetector(
              onTap: () => Get.offAllNamed(AppRoutes.rateTrip),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey300),
                  boxShadow: AppShadows.lg,
                ),
                child: const Center(
                  child: CustomText(
                    text: 'Rate Driver',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            20.height,
          ],
        ),
      ),
    );
  }

  Future<void> _downloadInvoice(String? tripId) async {
    if (tripId == null || tripId.isEmpty) {
      AppSnackbar.error('Invoice', 'Trip not found');
      return;
    }
    try {
      AppSnackbar.info('Invoice', 'Preparing your invoice...');
      await InvoiceService.openInvoice(tripId);
      // if (saved != null) AppSnackbar.success('Invoice', 'Invoice saved to your device');
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to download invoice';
      AppSnackbar.error('Invoice', msg);
    }
  }

  Future<void> _saveInvoice(String? tripId) async {
    if (tripId == null || tripId.isEmpty) {
      AppSnackbar.error('Invoice', 'Trip not found');
      return;
    }
    try {
      final saved = await InvoiceService.saveInvoice(tripId);
      if (saved != null) AppSnackbar.success('Invoice', 'Invoice saved to your device');
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to download invoice';
      AppSnackbar.error('Invoice', msg);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        16.width,
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomText(text: value, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        16.width,
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: CustomText(text: value, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRow(String label, String? value) {
    final safeValue = value ?? 'Cash';
    final IconData paymentIcon = safeValue.toLowerCase().contains('cash')
        ? Icons.account_balance_wallet_outlined
        : Icons.credit_card_outlined;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        16.width,
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(paymentIcon, size: 16, color: AppColors.slate500),
              6.width,
              Flexible(
                child: CustomText(
                  text: safeValue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
