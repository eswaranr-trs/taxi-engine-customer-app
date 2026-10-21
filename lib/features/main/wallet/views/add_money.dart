import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/controller/wallet_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class AddMoneyScreen extends GetView<WalletController> {
  const AddMoneyScreen({super.key});

  static const int _maxAmount = 99999;

  static const List<int> _presets = [1000, 2000, 5000, 10000];

  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_IN');

  int get _enteredAmount => int.tryParse(controller.addMoneyAmount.value.trim()) ?? 0;

  void _setAmount(int value) {
    final text = value.toString();
    controller.amountController.text = text;
    controller.amountController.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: CustomText(
          text: 'Add money',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkSlate,
          textAlign: TextAlign.start,
        ),
        elevation: 0,
        backgroundColor: AppColors.grey50,
        surfaceTintColor: AppColors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildCard()]),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          _buildBalanceRow(),
          const Divider(height: 1, color: AppColors.grey100),
          _buildAmountRow(),
          const Divider(height: 1, color: AppColors.grey100),
          _buildPresets(),
        ],
      ),
    );
  }

  Widget _buildBalanceRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.grey500),
          10.width,
          const Expanded(
            child: CustomText(
              text: 'Wallet balance',
              fontSize: 14,
              color: AppColors.grey600,
              textAlign: TextAlign.start,
            ),
          ),
          Obx(
            () => CustomText(
              text: controller.balanceLoaded.value ? '₹${_grouped.format(controller.walletBalance.value)}' : '––',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            text: 'AMOUNT',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.grey400,
            letterSpacing: 1.2,
            textAlign: TextAlign.start,
          ),
          10.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(
                () => CustomText(
                  text: '₹',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _enteredAmount > 0 ? AppColors.darkSlate : AppColors.grey300,
                ),
              ),
              8.width,
              Expanded(
                child: TextField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  cursorColor: AppColors.primary,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkSlate,
                    fontFamily: 'Poppins',
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.grey300,
                      fontFamily: 'Poppins',
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Obx(() {
        final int current = _enteredAmount;
        return Row(
          children: [
            for (final amount in _presets) ...[
              if (amount != _presets.first) 8.width,
              Expanded(
                child: GestureDetector(
                  onTap: () => _setAmount(amount),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current == amount ? AppColors.darkSlate : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: current == amount ? AppColors.darkSlate : AppColors.grey200),
                    ),
                    child: CustomText(
                      text: '₹$amount',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: current == amount ? AppColors.white : AppColors.grey600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final bool loading = controller.isAddingMoney.value;
            final int amount = _enteredAmount;
            final bool valid = amount > 0 && amount <= _maxAmount;

            return CustomButton(
              text: loading ? 'Processing...' : (valid ? 'Add ₹${_grouped.format(amount)}' : 'Continue'),
              loading: loading,
              enabled: valid && !loading,
              onPressed: controller.proceedAddMoney,
              gradient: valid ? AppColors.gradientButton : null,
              // color: valid ? null : AppColors.grey300,
              textColor: valid ? AppColors.black : AppColors.grey400,
            );
          }),
          10.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.grey400),
              6.width,
              const CustomText(text: 'Secured by Razorpay', fontSize: 10, color: AppColors.grey400),
            ],
          ),
        ],
      ),
    );
  }
}
