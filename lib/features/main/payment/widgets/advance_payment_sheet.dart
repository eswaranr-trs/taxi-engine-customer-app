import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/advance_payment_controller.dart';

class AdvancePaymentSheet {
  static Future<void> show({
    required String bookingId,
    required double totalFare,
    VoidCallback? onPaid,
    bool isScheduled = false,
  }) async {
    final controller = Get.put(AdvancePaymentController());
    controller.configure(bookingId: bookingId, totalFare: totalFare, onPaid: onPaid, isScheduled: isScheduled);

    await Get.bottomSheet(
      _AdvanceSheetBody(controller: controller),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );

    if (controller.awaitingGateway) {
      await controller.gatewayDone.timeout(const Duration(minutes: 10), onTimeout: () {});
    }

    if (Get.isRegistered<AdvancePaymentController>()) Get.delete<AdvancePaymentController>();
  }
}

class _AdvanceSheetBody extends StatelessWidget {
  final AdvancePaymentController controller;
  const _AdvanceSheetBody({required this.controller});

  String _money(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            20.height,
            const CustomText(text: 'Pay Advance', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.charcoal),
            6.height,
            CustomText(
              text: 'Pay a part of your fare now to secure the booking. The rest is paid after the trip.',
              fontSize: 13,
              color: AppColors.grey,
              textAlign: TextAlign.left,
            ),
            24.height,

            Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              if (controller.percentages.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CustomText(text: 'Advance payment is unavailable right now.', color: AppColors.grey),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    text: 'CHOOSE AMOUNT',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey650,
                  ),
                  12.height,
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.percentages.map((p) => _percentChip(p)).toList(),
                  ),
                  20.height,

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _summaryRow('Total fare', _money(controller.totalFare)),
                        10.height,
                        _summaryRow(
                          'Advance (${controller.selectedPercent.value}%)',
                          _money(controller.amount),
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                  24.height,

                  const CustomText(
                    text: 'PAYMENT METHOD',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey650,
                  ),
                  12.height,
                  _methodTile(
                    value: 'online',
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Online Payment',
                    subtitle: 'UPI, cards, netbanking',
                  ),

                  // 10.height,
                  // _methodTile(
                  //   value: 'wallet',
                  //   icon: Icons.wallet_outlined,
                  //   title: 'Wallet',
                  //   subtitle: 'Balance ${_money(controller.walletBalance.value)}',
                  //   disabled: controller.walletBalance.value < controller.amount,
                  // ),
                  24.height,
                  CustomButton(
                    text: controller.isPaying.value ? 'Processing...' : 'Pay ${_money(controller.amount)}',
                    onPressed: controller.isPaying.value ? () {} : controller.pay,
                    gradient: AppColors.gradientButton,
                    textColor: AppColors.white,
                    // icon: Icons.lock_outline,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _percentChip(int p) {
    return Obx(() {
      final bool selected = controller.selectedPercent.value == p;
      return GestureDetector(
        onTap: () => controller.selectedPercent.value = p,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? AppColors.primary : AppColors.grey300, width: 1.5),
          ),
          child: CustomText(
            text: '$p%',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.black : AppColors.grey,
          ),
        ),
      );
    });
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: highlight ? 14 : 13,
          fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          color: highlight ? AppColors.charcoal : AppColors.grey,
        ),
        CustomText(
          text: value,
          fontSize: highlight ? 16 : 13,
          fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
          color: highlight ? AppColors.primary : AppColors.charcoal,
        ),
      ],
    );
  }

  Widget _methodTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool disabled = false,
  }) {
    return Obx(() {
      final bool selected = controller.method.value == value;
      return Opacity(
        opacity: disabled ? 0.5 : 1,
        child: GestureDetector(
          onTap: disabled ? null : () => controller.method.value = value,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.primary : AppColors.grey300, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                14.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(text: title, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                      2.height,
                      CustomText(text: subtitle, fontSize: 12, color: AppColors.grey),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.grey400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
