import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/payment_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_mark_trigger.dart';

class PaymentScreen extends GetView<PaymentController> {
  const PaymentScreen({super.key});

  static final GlobalKey _coachPromoKey = GlobalKey();
  static final GlobalKey _coachFareKey = GlobalKey();
  static final GlobalKey _coachTipKey = GlobalKey();
  static final GlobalKey _coachWalletKey = GlobalKey();
  static final GlobalKey _coachMethodKey = GlobalKey();

  double _finalAmount(TripStateService s) {
    final t = s.selectedTrip;
    return t?.customerFinalAmount ?? t?.tripCompletedFinalAmount ?? t?.totalFare ?? t?.finalAmount ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final tripStateService = Get.find<TripStateService>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAllNamed(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          surfaceTintColor: AppColors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Container(
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 20),
                onPressed: () {
                  if (Get.key.currentState?.canPop() ?? false) {
                    Get.back();
                  } else {
                    Get.offAllNamed(AppRoutes.home);
                  }
                },
              ),
            ),
          ),
          title: const CustomText(
            text: 'Payment',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkSlate,
          ),
          centerTitle: true,
        ),
        body: AppRefreshIndicator(
          onRefresh: controller.refreshFare,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              sliver: SliverList.list(
                children: [
                  _buildAmountCard(tripStateService),
                  16.height,
                  KeyedSubtree(key: _coachPromoKey, child: _buildPromoSection(tripStateService)),
                  16.height,
                  KeyedSubtree(key: _coachFareKey, child: _buildFareBreakdown(tripStateService)),
                  16.height,
                  KeyedSubtree(key: _coachTipKey, child: _buildTipSection(tripStateService)),
                  20.height,
                  _buildWalletCredit(tripStateService),
                  Obx(() {
                    _ensureCashSheet(tripStateService);
                    return _buildMethodSection(tripStateService);
                  }),
                  CoachMarkTrigger(storageKey: 'payment_screen_coach', steps: _coachSteps),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(
          () => _isCashTrip(tripStateService) ? const SizedBox.shrink() : _buildFooter(tripStateService),
        ),
      ),
    );
  }

  List<CoachMark> _coachSteps() => [
    CoachMark(
      targetKey: _coachPromoKey,
      title: 'Promo code',
      description: 'Have a coupon? Apply it here before paying and the discount comes off your total.',
      holeRadius: 14,
    ),
    CoachMark(
      targetKey: _coachFareKey,
      title: 'Fare breakdown',
      description: 'Tap View Fare Breakdown to see base fare, taxes, tolls and any advance already paid.',
      holeRadius: 20,
    ),
    CoachMark(
      targetKey: _coachTipKey,
      title: 'Tip your driver',
      description: 'Optional. 100% of the tip goes to the driver and is added to your total.',
      holeRadius: 14,
    ),
    CoachMark(
      targetKey: _coachWalletKey,
      title: 'Wallet credit',
      description: 'Turn this on to pay part of the fare from your wallet balance.',
      holeRadius: 20,
      holePadding: 2,
    ),
    CoachMark(
      targetKey: _coachMethodKey,
      title: 'Payment method',
      description: 'Pay online, or choose Cash to settle directly with your driver.',
      holeRadius: 16,
      holePadding: 2,
    ),
  ];

  Widget _buildAmountCard(TripStateService tripStateService) {
    return Obx(() {
      final activeTrip = tripStateService.selectedTrip;
      final String pickUpPoint = activeTrip?.pickupLocation ?? 'Pickup';
      final String dropOffPoint = activeTrip?.destinationLocation ?? 'Drop';
      final String distance = '${activeTrip?.distanceInKm ?? ''} km';
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text: 'YOUR TRIP',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.grey400,
              letterSpacing: 1,
            ),
            14.height,

            _routeConnector(
              child: _routePoint(
                icon: Icons.my_location_rounded,
                color: AppColors.primary,
                address: pickUpPoint,
                maxLines: 2,
              ),
            ),
            _routePoint(icon: Icons.place_rounded, color: AppColors.darkSlate, address: dropOffPoint, maxLines: 3),
            14.height,
            Container(height: 1, color: AppColors.grey100),
            12.height,
            Row(
              children: [
                const Icon(Icons.directions_car_filled_outlined, size: 15, color: AppColors.slate500),
                6.width,
                CustomText(
                  text: 'Premium Sedan • $distance',
                  fontSize: 12,
                  color: AppColors.slate500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  static const double _badgeSize = 20;
  static const double _gapBetweenPoints = 16;

  Widget _routePoint({required IconData icon, required Color color, required String address, required int maxLines}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        12.width,
        Expanded(
          child: CustomText(
            text: address,
            fontSize: 14,
            height: 1.45,
            textAlign: TextAlign.left,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.w600,
            color: AppColors.darkSlate,
          ),
        ),
      ],
    );
  }

  Widget _routeConnector({required Widget child}) {
    return Stack(
      children: [
        const Positioned(
          left: _badgeSize / 2 - 1,
          top: _badgeSize + 4,
          bottom: 4,
          width: 2,
          child: DottedVerticalLine(),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: _gapBetweenPoints),
          child: child,
        ),
      ],
    );
  }

  Widget _buildFareBreakdown(TripStateService tripStateService) {
    return Obx(() {
      final t = tripStateService.selectedTrip;
      final double estimated = t?.estimatedFare ?? 0;
      final double serviceTax = t?.serviceTax ?? 0;
      final double toll = t?.tollAmount ?? 0;
      final double permit = t?.permitCharges ?? 0;
      final double driverAllowance = t?.driverAllowance ?? 0;
      final double driverCharges = t?.totalDriverCharges ?? 0;
      final double extraCharges = t?.totalExtraCharges ?? 0;
      final double tips = t?.tipsAmount ?? 0;
      final double tripDiscount = t?.discountAmount ?? 0;
      final double advance = t?.advanceAmount ?? 0;
      final double distanceKm = t?.tripCompletedDistance ?? t?.distanceInKm ?? 0;
      final double pricePerKm = t?.pricePerKm ?? 0;
      final double totalFare = _finalAmount(tripStateService);
      final double promo = controller.promoDiscount.value;
      final double payable = controller.payableAmount(totalFare);
      final double beforeDiscountAmount = payable + tripDiscount;

      final bool hasItems =
          estimated > 0 ||
          serviceTax > 0 ||
          toll > 0 ||
          permit > 0 ||
          driverAllowance > 0 ||
          driverCharges > 0 ||
          extraCharges > 0;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(text: 'Total Payable', fontSize: 13, color: AppColors.slate500),
            6.height,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  text: '₹${payable.toStringAsFixed(0)}',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                ),
                if (tripDiscount > 0) ...[
                  10.width,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: CustomText(
                      text: '₹${beforeDiscountAmount.toStringAsFixed(0)}',
                      fontSize: 15,
                      color: AppColors.grey400,
                      textDecoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (promo > 0) ...[
              4.height,
              CustomText(
                text: 'Promo ${controller.appliedPromo.value ?? ''} · −₹${promo.toStringAsFixed(0)}',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ],

            6.height,
            _dashedDivider(),

            GestureDetector(
              onTap: () => controller.showFareBreakdown.toggle(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: controller.showFareBreakdown.value ? 'Hide Fare Breakdown' : 'View Fare Breakdown',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    Icon(
                      controller.showFareBreakdown.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            if (controller.showFareBreakdown.value) ...[
              if (distanceKm > 0) ...[10.height, _metaRow('Distance Traveled', '${_amt(distanceKm)} km')],
              if (pricePerKm > 0) ...[10.height, _fareRow('Price per KM', pricePerKm), 10.height],
              if (hasItems) ...[
                if (estimated > 0) _fareRow('Base Fare', estimated),
                if (serviceTax > 0) ...[10.height, _fareRow('Service Tax', serviceTax)],
                if (toll > 0) ...[10.height, _fareRow('Toll Charges', toll)],
                if (permit > 0) ...[10.height, _fareRow('Permit Charges', permit)],
                if (driverAllowance > 0) ...[10.height, _fareRow('Driver Allowance', driverAllowance)],
                if (driverCharges > 0) ...[10.height, _fareRow('Driver Charges', driverCharges)],
                if (extraCharges > 0) ...[10.height, _fareRow('Extra Charges', extraCharges)],
                if (tips > 0) ...[10.height, _fareRow('Driver Tip', tips)],
                if (tripDiscount > 0) ...[10.height, _fareRow('Discount', tripDiscount, negative: true)],
                if (advance > 0) ...[10.height, _fareRow('Advance Paid', advance, negative: true)],
                4.height,
              ] else
                _fareRow('Ride Fare', totalFare),
              12.height,
              _dashedDivider(),
              12.height,
              _fareRow('Total Fare', payable, emphasize: true),
            ],
          ],
        ),
      );
    });
  }

  String _amt(double v) => v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _metaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 13, color: AppColors.slate500, textAlign: TextAlign.left),
        CustomText(text: value, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkSlate),
      ],
    );
  }

  Widget _fareRow(String label, double value, {bool negative = false, bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: emphasize ? 14 : 13,
          fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
          color: emphasize ? AppColors.darkSlate : AppColors.slate500,
          textAlign: TextAlign.left,
        ),
        CustomText(
          text: '${negative ? '−' : ''}₹${_amt(value)}',
          fontSize: emphasize ? 15 : 13,
          fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
          color: negative ? AppColors.red : AppColors.darkSlate,
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) => Container(width: dashWidth, height: 1, color: AppColors.grey200)),
        );
      },
    );
  }

  Widget _buildTipSection(TripStateService tripStateService) {
    return Obx(() {
      final int applied = (tripStateService.selectedTrip?.tipsAmount ?? 0).round();
      final bool expanded = controller.showTipField.value;

      if (!expanded) {
        final bool has = applied > 0;
        return GestureDetector(
          onTap: () => controller.showTipField.value = true,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: has ? AppColors.green.withValues(alpha: 0.08) : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: has ? AppColors.green.withValues(alpha: 0.4) : AppColors.grey100),
            ),
            child: Row(
              children: [
                Icon(
                  has ? Icons.favorite_rounded : Icons.volunteer_activism_outlined,
                  color: has ? AppColors.green : AppColors.primary,
                  size: 20,
                ),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: has ? 'Tip added · ₹$applied' : 'Add a tip for your driver',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: has ? AppColors.green : AppColors.darkSlate,
                        textAlign: TextAlign.left,
                      ),
                      2.height,
                      CustomText(
                        text: has ? 'Thank you for your tip!' : 'Show your appreciation',
                        fontSize: 11,
                        color: AppColors.slate500,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (has ? AppColors.green : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    text: has ? 'Edit' : 'Add Tip',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: has ? AppColors.green : AppColors.primary,
                  ),
                ),
                if (has) ...[
                  8.width,
                  GestureDetector(
                    onTap: controller.isApplyingTip.value ? null : controller.removeTip,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      const List<int> presets = [20, 50, 100];
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism_outlined, size: 18, color: AppColors.primary),
                8.width,
                const Expanded(
                  child: CustomText(
                    text: 'Tip your driver',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.left,
                  ),
                ),
                GestureDetector(
                  onTap: () => controller.showTipField.value = false,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.keyboard_arrow_up, size: 20, color: AppColors.grey400),
                  ),
                ),
              ],
            ),
            4.height,
            const CustomText(
              text: '100% of your tip goes to the driver. Added to your total.',
              fontSize: 12,
              color: AppColors.slate500,
              textAlign: TextAlign.left,
            ),
            14.height,
            Obx(
              () => Row(
                children: [
                  for (final amt in presets) ...[Expanded(child: _tipChip(amt)), if (amt != presets.last) 10.width],
                ],
              ),
            ),
            12.height,
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const CustomText(
                          text: '₹',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey500,
                        ),
                        8.width,
                        Expanded(
                          child: TextField(
                            controller: controller.tipController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            onChanged: (v) {
                              if (v.trim().isNotEmpty) controller.pendingTip.value = 0;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Other',
                              hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: const TextStyle(color: AppColors.darkSlate, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                10.width,
                Obx(
                  () => GestureDetector(
                    onTap: controller.isApplyingTip.value ? null : controller.applyTip,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientButton,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: controller.isApplyingTip.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const CustomText(
                                text: 'Add Tip',
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
            if (applied > 0) ...[
              12.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text: 'Current tip ₹$applied.',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.isApplyingTip.value ? null : controller.removeTip,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.red),
                          6.width,
                          const CustomText(
                            text: 'Remove Tip',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _tipChip(int amount) {
    final bool isSelected = controller.pendingTip.value == amount && controller.tipController.text.trim().isEmpty;
    return GestureDetector(
      onTap: () {
        controller.pendingTip.value = isSelected ? 0 : amount;
        controller.tipController.clear();
        controller.tipController.text = amount.toString();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey100, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomText(
          text: '₹$amount',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.primary : AppColors.grey600,
        ),
      ),
    );
  }

  Widget _buildMethodSection(TripStateService tripStateService) {
    final double payable = controller.payableAmount(_finalAmount(tripStateService));
    if (controller.remainingAfterWallet(payable) <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: controller.walletCreditFor(payable) > 0 ? 'Pay the remaining amount using' : 'Payment Methods',
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.darkSlate,
          textAlign: TextAlign.left,
        ),
        10.height,

        Obx(
          key: _coachMethodKey,
          () => Column(
            children: [
              _buildPaymentOption(
                value: 'upi',
                icon: Icons.account_balance,
                title: 'Online Payment',
                subtitle: 'UPI, Cards and Net Banking',
              ),
              12.height,
              _buildPaymentOption(
                value: 'cash',
                icon: Icons.payments_outlined,
                title: 'Cash',
                subtitle: 'Pay the driver directly',
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isCashTrip(TripStateService s) => controller.isAwaitingCashFor(s.selectedTrip?.bookingId);

  Future<void> _confirmCash(double amount) async {
    final bool? ok = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
                child: const Icon(Icons.payments_outlined, size: 28, color: AppColors.warning),
              ),
              16.height,
              const CustomText(text: 'Confirm Cash Payment', fontSize: 17, fontWeight: FontWeight.bold),
              10.height,
              CustomText(
                text: '₹${_amt(amount)}',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
              10.height,
              const CustomText(
                text: 'Pay this amount directly to your driver.',
                fontSize: 13,
                color: AppColors.slate500,
                textAlign: TextAlign.center,
              ),
              22.height,
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CustomText(text: 'Cancel', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientButton,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CustomText(
                            text: 'Confirm',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
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
    );

    if (ok == true) controller.startPayment(amount: amount);
  }

  Widget _buildWalletCredit(TripStateService tripStateService) {
    return Obx(() {
      final double payable = controller.payableAmount(_finalAmount(tripStateService));
      final double cap = controller.walletCap(payable);
      if (cap <= 0) return const SizedBox.shrink();

      final double credit = controller.walletCreditFor(payable);
      final bool on = controller.useWallet.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          key: _coachWalletKey,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primary),
                    ),
                    16.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomText(
                            text: 'Wallet Credit',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                            textAlign: TextAlign.start,
                          ),
                          2.height,
                          CustomText(
                            text: 'Balance ₹${_amt(controller.walletBalance.value)}',
                            fontSize: 12,
                            color: AppColors.grey400,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                    if (on && credit > 0)
                      CustomText(
                        text: '− ₹${_amt(credit)}',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    10.width,
                    GestureDetector(
                      onTap: controller.useWallet.toggle,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: on ? AppColors.primary : AppColors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: on ? AppColors.primary : AppColors.grey200, width: 1.5),
                        ),
                        child: on ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white) : null,
                      ),
                    ),
                  ],
                ),
              ),

              if (on) ...[
                Container(height: 1, color: AppColors.grey100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _walletChips(cap, credit),
                      if (controller.showWalletOther.value) ...[10.height, _walletOtherField(cap)],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _walletChips(double cap, double credit) {
    double? mid;
    for (final v in <double>[2000, 1000, 500]) {
      if (v < cap) {
        mid = v;
        break;
      }
    }

    final bool other = controller.showWalletOther.value;

    return Row(
      children: [
        if (mid != null) ...[
          Expanded(
            child: _walletChip('₹${_amt(mid)}', !other && credit == mid, () => controller.setWalletCredit(mid!)),
          ),
          8.width,
        ],
        Expanded(child: _walletChip('₹${_amt(cap)}', !other && credit == cap, () => controller.setWalletCredit(cap))),
        8.width,
        Expanded(child: _walletChip('Other', other, controller.showWalletOther.toggle)),
      ],
    );
  }

  Widget _walletChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.grey100, width: 1.5),
        ),
        child: CustomText(
          text: label,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: selected ? AppColors.primary : AppColors.grey600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _walletOtherField(double cap) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                const CustomText(text: '₹', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.grey500),
                8.width,
                Expanded(
                  child: TextField(
                    controller: controller.walletController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                    decoration: InputDecoration(
                      hintText: 'Up to ${_amt(cap)}',
                      hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(color: AppColors.darkSlate, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        10.width,
        GestureDetector(
          onTap: () {
            final double v = double.tryParse(controller.walletController.text.trim()) ?? 0;
            controller.setWalletCredit(v.clamp(0, cap));
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: AppColors.gradientButton, borderRadius: BorderRadius.circular(12)),
            child: const CustomText(text: 'Apply', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  static bool _cashSheetOpen = false;

  void _ensureCashSheet(TripStateService tripStateService) {
    if (_cashSheetOpen || !_isCashTrip(tripStateService)) return;
    _cashSheetOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.bottomSheet(
        PopScope(canPop: false, child: _buildCashWaiting(tripStateService)),
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: AppColors.transparent,
      ).whenComplete(() => _cashSheetOpen = false);
    });
  }

  Widget _buildCashWaiting(TripStateService tripStateService) {
    return Obx(() {
      final double payable = controller.remainingAfterWallet(controller.payableAmount(_finalAmount(tripStateService)));
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
              child: const Icon(Icons.payments_outlined, size: 26, color: AppColors.warning),
            ),
            14.height,
            const CustomText(text: 'Pay your driver in cash', fontSize: 13, color: AppColors.slate500),
            6.height,
            CustomText(
              text: '₹${payable.toStringAsFixed(0)}',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
                ),
                10.width,
                const Flexible(
                  child: CustomText(
                    text: 'Waiting for Payment Confirmation',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            14.height,
            const CustomText(
              text: 'This trip is marked as Paid once your driver confirms the cash.',
              fontSize: 11,
              color: AppColors.slate500,
              textAlign: TextAlign.center,
              height: 1.45,
            ),
            if ((controller.cashWaitingNotice.value ?? '').isNotEmpty) ...[
              14.height,
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                    10.width,
                    Expanded(
                      child: CustomText(
                        text: controller.cashWaitingNotice.value!,
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.left,
                        maxLines: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildFooter(TripStateService tripStateService) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      decoration: const BoxDecoration(color: AppColors.backgroundColor),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final String? error = controller.paymentError.value;
            if (error == null || error.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                  10.width,
                  Expanded(
                    child: CustomText(
                      text: error,
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.darkSlate,
                      textAlign: TextAlign.left,
                      maxLines: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final double total = controller.payableAmount(_finalAmount(tripStateService));
            final double payable = controller.remainingAfterWallet(total);
            final bool cash = controller.selectedPaymentMethod.value == 'cash';
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: GestureDetector(
                onTap: controller.isLoading.value
                    ? null
                    : () {
                        if (cash) {
                          _confirmCash(payable);
                        } else {
                          controller.startPayment(amount: total);
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.gradientButton,
                  ),
                  child: Center(
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: cash
                                    ? 'Confirm Cash Payment'
                                    : (payable > 0 ? 'Pay ₹${_amt(payable)}' : 'Confirm Payment'),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              8.width,
                              const Icon(Icons.arrow_forward, color: AppColors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            );
          }),

          10.height,

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.grey400, size: 12),
              CustomText(
                text: 'Secured by Razorpay',
                fontSize: 10,
                color: AppColors.grey400,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection(TripStateService tripStateService) {
    final double baseTotal = _finalAmount(tripStateService);
    return Obx(() {
      final applied = controller.appliedPromo.value;

      if (applied != null && controller.promoDiscount.value > 0) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: AppColors.green, size: 18),
              10.width,
              Expanded(
                child: CustomText(
                  text: '$applied applied · You saved ₹${controller.promoDiscount.value.toStringAsFixed(0)}',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                  textAlign: TextAlign.left,
                ),
              ),
              GestureDetector(
                onTap: controller.clearPromo,
                child: const CustomText(
                  text: 'Remove',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        );
      }

      if (!controller.showPromoField.value) {
        return GestureDetector(
          onTap: () => controller.showPromoField.value = true,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 18),
                10.width,
                const Expanded(
                  child: CustomText(
                    text: 'Apply Promo Code',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.left,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_right, color: AppColors.grey400, size: 20),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.promoController,
                  onChanged: (_) => controller.promoError.value = null,
                  textCapitalization: TextCapitalization.characters,
                  label: 'Enter promo code',
                ),
              ),
              10.width,
              GestureDetector(
                onTap: controller.isApplyingPromo.value ? null : () => controller.applyPromo(baseTotal),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientButton,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: controller.isApplyingPromo.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const CustomText(
                            text: 'Apply',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (controller.promoError.value != null) ...[
            6.height,
            CustomText(
              text: controller.promoError.value!,
              fontSize: 12,
              color: AppColors.red,
              textAlign: TextAlign.left,
            ),
          ],
        ],
      );
    });
  }

  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool disabled = false,
  }) {
    final bool isSelected = !disabled && controller.selectedPaymentMethod.value == value;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : () => controller.selectPaymentMethod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey100, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.grey50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: disabled ? AppColors.grey400 : AppColors.primary, size: 20),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: title,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                      textAlign: TextAlign.start,
                    ),
                    2.height,
                    CustomText(
                      text: subtitle,
                      fontSize: 12,
                      color: disabled ? AppColors.red : AppColors.grey400,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey200, width: 1.5),
                ),
                child: isSelected
                    ? const Center(
                        child: SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
