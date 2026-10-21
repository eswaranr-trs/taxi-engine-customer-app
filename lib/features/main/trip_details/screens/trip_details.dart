import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/features/main/home/widgets/cancel_ride_bottom_sheet.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/controllers/my_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/payment/widgets/advance_payment_sheet.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import '../controllers/trip_details_controller.dart';

class TripDetailsScreen extends GetView<TripDetailsController> {
  const TripDetailsScreen({super.key});

  Map<dynamic, dynamic> get _args => (Get.arguments is Map) ? Get.arguments as Map : const {};

  bool get _canAct => _args['canAct'] == true && !controller.isCancelled && !controller.isCompleted;
  bool get _advancePaid => _args['advancePaid'] == true;

  void _payAdvance() {
    final String id = (_args['bookingId'] ?? '').toString();
    if (id.isEmpty) {
      AppSnackbar.error('Pay Advance', 'Missing booking reference');
      return;
    }

    final tss = Get.find<TripStateService>();
    tss.muteAutoNav((_args['rawBookingId'] ?? '').toString());
    tss.muteAutoNav((_args['rawId'] ?? '').toString());

    AdvancePaymentSheet.show(
      bookingId: id,
      totalFare: double.tryParse('${_args['totalFare']}') ?? 0,
      onPaid: () {
        if (Get.isRegistered<MyTripsController>()) Get.find<MyTripsController>().refreshTrips();
        Get.back();
      },
      isScheduled: true,
    );
  }

  void _cancelBooking() {
    final String id = (_args['bookingId'] ?? '').toString();
    Get.bottomSheet(CancelRideBottomSheet(bookingId: id), isScrollControlled: true);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripDetailsController>(
      builder: (_) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            surfaceTintColor: AppColors.transparent,

            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Container(
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 20),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
            title: const CustomText(
              text: 'Trip Details',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: controller.isCancelled ? AppColors.red50 : AppColors.amber50,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.md,
                    ),
                    child: Icon(
                      controller.isCancelled ? Icons.close : Icons.check,
                      color: controller.isCancelled ? AppColors.red : AppColors.primary,
                      size: 40,
                    ),
                  ),
                  20.height,
                  CustomText(
                    text: controller.isCancelled
                        ? 'Trip Cancelled'
                        : controller.isCompleted
                        ? 'Trip Completed'
                        : 'Your Trip',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                  ),
                  8.height,
                  CustomText(
                    text: controller.isCancelled
                        ? 'This trip was cancelled. Any applicable refund will be processed soon.'
                        : controller.isCompleted
                        ? 'This trip has been completed. Thank you for riding with Orange Taxi.'
                        : 'Here are the details of your trip.',
                    fontSize: 14,
                    color: AppColors.slate500,
                    textAlign: TextAlign.center,
                  ),
                  10.height,

                  _buildLocationCard(),
                  16.height,

                  Row(
                    children: [
                      Expanded(child: _buildVehicleCard()),
                      16.width,
                      Expanded(child: _buildTimeCard()),
                    ],
                  ),
                  16.height,

                  if (controller.isRoundTrip && !controller.isCancelled) ...[_buildReturnDateCard(), 16.height],

                  if (controller.isCancelled) ...[
                    _buildCancellationCard(),
                    16.height,
                  ] else ...[
                    _buildPassengerCard(),
                    16.height,

                    _buildFareCard(),
                    16.height,
                    _buildPaymentCard(),
                    16.height,
                  ],

                  if (_canAct) ...[
                    if (!_advancePaid)
                      CustomButton(
                        text: 'Pay Advance',
                        gradient: AppColors.gradientButton,
                        textColor: AppColors.white,
                        onPressed: _payAdvance,
                      ),
                    12.height,
                    CustomButton(text: 'Cancel Booking', color: AppColors.grey200, onPressed: _cancelBooking),
                    16.height,
                  ],

                  if (!controller.isCancelled && controller.isCompleted) ...[
                    Obx(() {
                      final downloading = controller.isDownloadingInvoice.value;
                      final saving = controller.isSavingInvoice.value;
                      return Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'View Invoice',
                              icon: Icons.receipt_long,
                              gradient: AppColors.gradientButton,
                              textColor: AppColors.white,
                              loading: downloading,
                              fontsize: 13,
                              onPressed: controller.downloadInvoice,
                            ),
                          ),
                          12.width,
                          Expanded(
                            child: CustomButton(
                              text: saving ? 'Downloading...' : ' Download invoice',
                              icon: Icons.file_download_outlined,
                              color: AppColors.white,
                              textColor: AppColors.darkSlate,
                              border: Border.all(color: AppColors.grey200),
                              onPressed: controller.saveInvoice,
                              fontsize: 13,
                            ),
                          ),
                        ],
                      );
                    }),
                    16.height,
                  ],

                  if (controller.isCancelled) ...[
                    ClipRRect(
                      borderRadius: AppRadius.rSm,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: 4, color: AppColors.warning),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: AppColors.grey100),
                                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: AppShadows.lg,
                                      ),
                                      child: const Icon(Icons.info, size: 20, color: AppColors.warning),
                                    ),
                                    12.width,
                                    const Expanded(
                                      child: CustomText(
                                        text:
                                            "If you have paid an advance, any eligible amount will be refunded automatically to your wallet.",
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                        textAlign: TextAlign.left,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  20.height,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timelineHeading(filled: false, label: 'PICKUP LOCATION'),

                _timelineBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: controller.pickupLocation,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.start,
                      ),

                      if (controller.hasStops) _buildStopsSection(),
                    ],
                  ),
                ),

                _timelineHeading(filled: true, label: 'DESTINATION'),

                Padding(
                  padding: const EdgeInsets.only(left: _railIndent, top: 4),
                  child: CustomText(
                    text: controller.destination,
                    fontSize: 13,
                    textAlign: TextAlign.start,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          12.width,

          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const CustomText(text: 'DISTANCE', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),

                4.height,

                CustomText(
                  text: controller.distance,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _dotSize = 12;
  static const double _railIndent = 28;

  Widget _timelineHeading({required bool filled, required String label}) {
    return Row(
      children: [
        Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
        (_railIndent - _dotSize).width,
        Expanded(
          child: CustomText(
            text: label,
            fontSize: 10,
            textAlign: TextAlign.start,
            fontWeight: FontWeight.bold,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    final bool paid = controller.isPaid;
    final String raw = controller.paymentMethodRaw.toLowerCase();
    final IconData icon = raw == 'cash'
        ? Icons.payments_outlined
        : raw == 'wallet'
        ? Icons.account_balance_wallet_outlined
        : Icons.account_balance;

    final Color accent = paid ? AppColors.successGreen : AppColors.warning;
    final Color accentBg = paid ? AppColors.successGreenLight : AppColors.amber50;
    final String? paidAt = controller.paymentDateText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 24, color: accent),
              ),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomText(
                      text: 'Payment Method',
                      fontSize: 12,
                      color: AppColors.slate500,
                      textAlign: TextAlign.left,
                    ),
                    2.height,
                    CustomText(
                      text: paid ? controller.paidViaText : 'Pay via ${controller.paymentMethodLabel}',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    2.height,
                    CustomText(
                      text: paid
                          ? (paidAt == null ? 'Payment Successful' : 'Payment Successful ● $paidAt')
                          : 'Payment Pending',
                      fontSize: 11,
                      color: AppColors.slate500,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              10.width,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(paid ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 15, color: accent),
                    5.width,
                    CustomText(
                      text: paid ? 'Paid' : 'Pending',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineBody({required Widget child}) {
    return Stack(
      children: [
        const Positioned(left: _dotSize / 2 - 1, top: 0, bottom: 0, width: 2, child: DottedVerticalLine()),
        Padding(
          padding: const EdgeInsets.only(left: _railIndent, top: 4, bottom: 18),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ],
    );
  }

  Widget _buildStopsSection() {
    final stops = controller.stops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        CustomText(
          text: stops.length > 1 ? 'STOPS (${stops.length})' : 'STOP',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.grey400,
        ),
        ...stops.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.trip_origin, size: 11, color: AppColors.orange),
                ),
                8.width,
                Expanded(
                  child: CustomText(
                    text: controller.stopLabel(e.key),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnDateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_repeat_outlined, color: AppColors.primary, size: 20),
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomText(
                  text: 'RETURN DATE',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey400,
                  textAlign: TextAlign.left,
                  letterSpacing: 0.5,
                ),
                4.height,
                CustomText(
                  text: controller.dropDate,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          10.width,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CustomText(
              text: 'Round Trip',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(text: 'VEHICLE TYPE', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),
          12.height,
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.directions_car_outlined, color: AppColors.primary, size: 20),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: controller.vehicleType,
                      fontSize: 12,
                      textAlign: TextAlign.left,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                    CustomText(
                      text: controller.vehicleModel,
                      fontSize: 12,
                      color: AppColors.slate500,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(text: 'PICKUP TIME', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),
          12.height,
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppShadows.md,
                ),
                child: const Icon(Icons.access_time_outlined, color: AppColors.primary, size: 20),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: controller.pickupDate,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.start,

                      color: AppColors.darkSlate,
                    ),
                    controller.status != 'completed' && controller.status != 'cancelled'
                        ? CustomText(
                            text: controller.pickupETA,
                            fontSize: 12,
                            color: AppColors.slate500,
                            textAlign: TextAlign.left,
                          )
                        : CustomText(text: '-', fontSize: 12, color: AppColors.slate500),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CustomText(
                text: 'REASON FOR CANCELLATION',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.grey400,
              ),
            ],
          ),
          12.height,
          CustomText(
            text: controller.cancellationReason,
            fontSize: 14,
            color: AppColors.darkSlate,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText(
                text: 'PASSENGER DETAILS',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.grey400,
              ),
            ],
          ),
          16.height,
          Row(
            children: [
              const AvatarImage(size: 40),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: controller.passengerName,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                    CustomText(text: controller.passengerPhone, fontSize: 12, color: AppColors.slate500),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(text: 'FARE ESTIMATE', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),
          16.height,
          if (controller.hasDistance) _buildFareRow('Total Distance', controller.distance),
          if (controller.hasPricePerKm) ...[12.height, _buildFareRow('Price per KM', controller.pricePerKm)],
          if (controller.hasEstimated) ...[12.height, _buildFareRow('Estimated Fare', controller.estimatedFare)],
          if (controller.hasServiceTax) ...[12.height, _buildFareRow('Service Tax', controller.serviceTax)],
          if (controller.hasToll) ...[12.height, _buildFareRow('Toll Charges', controller.tollAmount)],
          if (controller.hasDriverAllowance) ...[
            12.height,
            _buildFareRow('Driver Allowance', controller.driverAllowance),
          ],
          if (controller.hasPermitCharges) ...[12.height, _buildFareRow('Permit Charges', controller.permitCharges)],
          if (controller.hasDriverCharges) ...[12.height, _buildFareRow('Driver Charges', controller.driverCharges)],
          if (controller.hasTips) ...[12.height, _buildFareRow('Driver Tip', controller.tipsAmount)],
          if (controller.hasExtraCharges) ...[12.height, _buildFareRow('Extra Charges', controller.extraCharges)],
          if (controller.hasDiscount) ...[12.height, _buildFareRow('Discount', controller.discountAmount)],
          if (controller.hasAdvance) ...[12.height, _buildFareRow('Advance Paid', controller.advanceAmount)],
          6.height,
          Divider(color: AppColors.grey200),
          6.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText(
                text: 'Total Fare',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
              CustomText(
                text: controller.totalFare,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
            ],
          ),
          // 10.height,
          (!controller.isCancelled && controller.status != 'completed')
              ? ClipRRect(
                  borderRadius: AppRadius.rSm,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 4, color: AppColors.warning),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: AppColors.grey50),
                            padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.lg,
                                  ),
                                  child: const Icon(Icons.info, size: 20, color: AppColors.warning),
                                ),
                                12.width,
                                const Expanded(
                                  child: CustomText(
                                    text:
                                        'Final fare may vary based on additional distance travelled and applicable toll charges.',
                                    fontSize: 11,
                                    color: AppColors.slate500,
                                    textAlign: TextAlign.left,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 13, color: AppColors.slate500),
        CustomText(
          text: value,
          fontSize: 13,
          color: (label == 'Discount' || label == 'Advance Paid') ? AppColors.red : AppColors.slate500,
        ),
      ],
    );
  }
}
