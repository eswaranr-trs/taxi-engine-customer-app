import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/controller/wallet_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class AddMoneySuccessScreen extends GetView<WalletController> {
  const AddMoneySuccessScreen({super.key});

  void _exit() {
    final resume = WalletController.pendingAfterTopUp;
    WalletController.pendingAfterTopUp = null;
    Get.back();
    if (resume != null) {
      resume();
      return;
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final String transactionId = controller.lastTransactionId ?? '-';
    final String amountPaid = '₹${controller.lastTopUpAmount.toStringAsFixed(2)}';
    final String paymentMethod = controller.paymentMethodLabel;
    final String formattedDate = DateFormat('MMM dd, yyyy, hh:mm a').format(controller.lastTopUpDate ?? DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 5, spreadRadius: 1)],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.darkSlate, size: 20),
              onPressed: _exit,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              Lottie.asset('assets/lotties/success.json', height: 250, width: 250, repeat: true),
              Center(
                child: CustomText(
                  text: 'Top-Up Successful',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkSlate,
                ),
              ),
              8.height,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomText(
                  text: '$amountPaid has been added to your wallet',
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                    _buildDetailRow('Transaction ID', transactionId),
                    16.height,
                    _buildAmountRow('Amount Paid', amountPaid),
                    16.height,
                    _buildPaymentMethodRow('Payment Method', paymentMethod),
                    16.height,
                    _buildDetailRow('Date & Time', formattedDate),
                  ],
                ),
              ),
              40.height,
              CustomButton(text: "Done", gradient: AppColors.gradientButton, onPressed: _exit),

              20.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        CustomText(text: value, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
      ],
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        CustomText(text: value, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
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
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(paymentIcon, size: 16, color: AppColors.slate500),
            8.width,
            CustomText(text: safeValue, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
          ],
        ),
      ],
    );
  }
}
