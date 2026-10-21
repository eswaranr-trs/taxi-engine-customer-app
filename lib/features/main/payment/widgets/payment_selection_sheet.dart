import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/payment_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';

class PaymentBottomSheet extends StatefulWidget {
  const PaymentBottomSheet({super.key});

  static void show(BuildContext context) async {
    if (!Get.isRegistered<PaymentController>()) {
      Get.put(PaymentController());
    }
    await Get.bottomSheet(const PaymentBottomSheet(), isScrollControlled: true, backgroundColor: AppColors.transparent);
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final PaymentController controller = Get.find<PaymentController>();
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  final GlobalKey _contentKey = GlobalKey();
  final RxDouble _maxFrac = 0.6.obs;
  double _screenH = 0;
  late final Worker _bookingForWorker;
  Worker? _offerWorker;

  static const String _coachKey = 'payment_selection_coach';
  final GlobalKey _coachMethodsKey = GlobalKey();
  final GlobalKey _coachBookingForKey = GlobalKey();
  final GlobalKey _coachOffersKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    _bookingForWorker = ever(controller.selectedBookingFor, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());
    });
    if (Get.isRegistered<VehicleSelectionController>()) {
      final vsc = Get.find<VehicleSelectionController>();
      _offerWorker = everAll([vsc.appliedOfferId, vsc.vehicles], (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());
      });
    }
    _maybeShowCoachMarks();
  }

  Future<void> _maybeShowCoachMarks() async {
    if (!await LocalStorageService.isSignupUser()) return;
    if (await LocalStorageService.hasSeenCoachMark(_coachKey)) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    CoachMarks.show(context, steps: _coachSteps(), onFinish: () => LocalStorageService.setSeenCoachMark(_coachKey));
  }

  List<CoachMark> _coachSteps() {
    return [
      CoachMark(
        targetKey: _coachMethodsKey,
        title: 'How you pay',
        description: 'Pay from your wallet, in cash to the driver, or online. Tap + to top up your wallet.',
        holeRadius: 18,
      ),
      CoachMark(
        targetKey: _coachBookingForKey,
        title: 'Booking for someone else?',
        description: 'Switch to Others and add their name and number so the driver contacts the right person.',
        holeRadius: 18,
      ),
      CoachMark(
        targetKey: _coachOffersKey,
        title: 'Offers',
        description: 'Enter an offer code and tap Apply, or browse everything available under View All Offers.',
        holeRadius: 16,
      ),
    ];
  }

  void _syncExtent() {
    final ctx = _contentKey.currentContext;
    if (ctx == null || _screenH <= 0) return;
    final double h = ctx.size?.height ?? 0;
    if (h <= 0) return;
    final double frac = ((h + 80) / _screenH).clamp(0.4, 0.95);
    if ((frac - _maxFrac.value).abs() < 0.005) return;
    _maxFrac.value = frac;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetCtrl.isAttached) {
        _sheetCtrl.animateTo(frac, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    CoachMarks.dismiss();
    _bookingForWorker.dispose();
    _offerWorker?.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenH = MediaQuery.of(context).size.height;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());
    return Obx(() {
      final double maxF = _maxFrac.value;
      return DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: maxF,
        minChildSize: 0.35,
        maxChildSize: maxF,
        builder: (context, scrollController) {
          return _buildSheetBody(context, scrollController);
        },
      );
    });
  }

  Widget _buildSheetBody(BuildContext context, ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),

      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

        child: Column(
          key: _contentKey,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,

                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
              ),
            ),

            10.height,

            const CustomText(
              text: 'PAYMENT METHODS',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.grey650,
              textAlign: TextAlign.left,
            ),

            20.height,

            // Obx(
            //   key: _coachMethodsKey,
            //   () => _buildSelectionRow(
            //     icon: Icons.account_balance_wallet_outlined,
            //     iconColor: AppColors.primary,
            //     title: 'Wallet Balance',
            //     subtitle: controller.isWalletUsable
            //         ? '₹${controller.walletBalance.value.toStringAsFixed(2)}'
            //         : '₹0.00 · Add money to use this',
            //     value: 'wallet',
            //     groupValue: controller.selectedPaymentMethod.value,
            //     enabled: controller.isWalletUsable,
            //     onChanged: (val) => controller.selectPaymentMethod(val!),
            //     trailing: GestureDetector(
            //       behavior: HitTestBehavior.opaque,
            //       onTap: () async {
            //         await Get.toNamed(AppRoutes.addMoney);
            //         controller.getCustomerWallet();
            //       },
            //       child: Padding(
            //         padding: const EdgeInsets.all(8),
            //         child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
            //       ),
            //     ),
            //     onTrailingTap: () async {
            //       await Get.toNamed(AppRoutes.addMoney);
            //       controller.getCustomerWallet();
            //     },
            //   ),
            // ),
            Obx(
              () => _buildSelectionRow(
                icon: Icons.payments_outlined,
                iconColor: AppColors.grey650,
                title: 'Online',
                value: 'upi',
                groupValue: controller.selectedPaymentMethod.value,
                onChanged: (val) => controller.selectPaymentMethod(val!),
              ),
            ),

            const Divider(height: 1, color: AppColors.grey100),
            Obx(
              () => _buildSelectionRow(
                icon: Icons.payments_outlined,
                iconColor: AppColors.grey650,
                title: 'Cash',
                value: 'cash',
                groupValue: controller.selectedPaymentMethod.value,
                onChanged: (val) => controller.selectPaymentMethod(val!),
              ),
            ),
            20.height,
            const CustomText(
              text: 'BOOKING FOR',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.grey650,
              textAlign: TextAlign.left,
            ),

            20.height,

            Obx(
              key: _coachBookingForKey,
              () => _buildSelectionRow(
                icon: Icons.person_outline,
                iconColor: AppColors.primary,
                title: 'Myself',
                value: 'myself',
                groupValue: controller.selectedBookingFor.value,
                onChanged: (val) => controller.selectBookingFor(val!),
              ),
            ),

            const Divider(height: 1, color: AppColors.grey100),

            Obx(
              () => _buildSelectionRow(
                icon: Icons.group_outlined,
                iconColor: AppColors.primary,
                title: 'Others',
                value: 'others',
                groupValue: controller.selectedBookingFor.value,
                onChanged: (val) => controller.selectBookingFor(val!),
              ),
            ),
            Obx(() {
              if (controller.selectedBookingFor.value != 'others') {
                return const SizedBox(width: double.infinity);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  10.height,

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Phone Number',
                          controller: controller.phoneNumberController,
                          keyboardType: TextInputType.phone,
                          readOnly: controller.isPhoneConfirmed.value,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'\d')),
                            LengthLimitingTextInputFormatter(10),
                          ],

                          suffix: Obx(
                            () => InkWell(
                              onTap: controller.isPhoneConfirmed.value ? null : controller.confirmPhone,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 15.0, right: 10),
                                child: CustomText(
                                  text: controller.isPhoneConfirmed.value ? 'Confirmed' : 'Confirm',
                                  color: controller.isPhoneConfirmed.value ? Colors.green : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  10.height,

                  GestureDetector(
                    onTap: controller.pickContact,
                    child: const CustomText(
                      text: 'Choose From Contacts',
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
            10.height,

            KeyedSubtree(key: _coachOffersKey, child: _buildOffersSection(context)),

            // 30.height,

            // /// Continue Button
            // CustomButton(
            //   text: 'Continue',
            //   onPressed: () {
            //     Get.back();
            //   },
            //   gradient: AppColors.gradientButton,
            //   textColor: AppColors.white,
            //   icon: Icons.arrow_forward,
            // ),

            // 20.height,
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    if (!Get.isRegistered<VehicleSelectionController>()) return const SizedBox.shrink();
    final vsc = Get.find<VehicleSelectionController>();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            text: 'OFFERS',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.grey650,
            textAlign: TextAlign.left,
          ),
          5.height,
          Obx(() {
            final String? manual = vsc.appliedOfferId.value;
            final String? code = (manual != null && manual.isNotEmpty) ? manual : vsc.activeOfferTitle;
            if (code == null || code.isEmpty) return const SizedBox.shrink();
            final bool removable = manual != null && manual.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.percent_rounded, size: 14, color: AppColors.white),
                  ),
                  10.width,
                  Expanded(
                    child: CustomText(
                      text: '$code Applied',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.normalText,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (removable)
                    InkWell(
                      onTap: vsc.isApplyingOffer.value ? null : () => vsc.removeOffer(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: CustomText(
                          text: 'Remove',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          Obx(() {
            final String? applied = vsc.appliedOfferId.value;
            if (applied != null && applied.isNotEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vsc.offerController,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) {
                            if (vsc.offerError.value != null) vsc.offerError.value = null;
                          },
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                            border: InputBorder.none,
                            hintText: 'Have an offer code? Enter here',
                            hintStyle: TextStyle(color: AppColors.grey, fontSize: 12),
                          ),
                          style: const TextStyle(fontSize: 14, color: AppColors.black, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Obx(
                        () => vsc.isApplyingOffer.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : InkWell(
                                onTap: () => vsc.applyOffer(),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  child: CustomText(
                                    text: 'Apply',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                Obx(() {
                  final String? err = vsc.offerError.value;
                  if (err == null || err.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: CustomText(text: err, fontSize: 12, color: AppColors.red, textAlign: TextAlign.left),
                  );
                }),
              ],
            );
          }),

          10.height,
          InkWell(
            onTap: () => Get.toNamed(AppRoutes.offers),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: CustomText(
                text: 'View All Offers >',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    Widget? trailing,
    VoidCallback? onTrailingTap,
    bool enabled = true,
  }) {
    final bool isSelected = enabled && value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : (enabled ? AppColors.grey : AppColors.grey300),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                      ),
                    )
                  : null,
            ),
            12.width,
            Icon(icon, color: enabled ? iconColor : AppColors.grey400, size: 22),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.left,
                    color: enabled ? AppColors.normalText : AppColors.grey500,
                  ),
                  if (subtitle != null)
                    CustomText(
                      text: subtitle,
                      fontSize: 12,
                      color: enabled ? AppColors.grey650 : AppColors.grey400,
                      textAlign: TextAlign.left,
                    ),
                ],
              ),
            ),
            if (trailing != null) InkWell(onTap: onTrailingTap, child: trailing),
          ],
        ),
      ),
    );
  }
}
