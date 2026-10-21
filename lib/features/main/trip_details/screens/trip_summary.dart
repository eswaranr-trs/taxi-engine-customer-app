import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_mark_trigger.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/controllers/my_trips_controller.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/legal_api/legal_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/legal/model/legal_document.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/payment/widgets/advance_payment_sheet.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import '../controllers/trip_details_controller.dart';

class TripSummaryScreen extends GetView<TripDetailsController> {
  TripSummaryScreen({super.key}) : _args = (Get.arguments is Map) ? Get.arguments as Map : const {} {
    _loadTerms();
  }

  final Map<dynamic, dynamic> _args;

  final TripsRepository _tripsRepo = TripsRepository();
  final LegalRepository _legalRepo = LegalRepository();
  final RxBool isConfirming = false.obs;
  final RxBool payAdvance = false.obs;
  final Rxn<LegalDocument> terms = Rxn<LegalDocument>();
  final RxBool termsExpanded = false.obs;
  final GlobalKey _coachAdvanceKey = GlobalKey();

  Future<void> _loadTerms() async {
    try {
      final String serviceType = Get.isRegistered<TripController>() ? Get.find<TripController>().serviceType : '';
      terms.value = await _legalRepo.getDocument(LegalDocType.termsAndConditions, serviceType: serviceType);
    } catch (_) {}
  }

  double get _totalFareValue => double.tryParse(controller.totalFare.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  bool get _isScheduled => _args['isScheduled'] == true;

  void _openAdvanceSheet() {
    final String id = controller.bookingId;
    if (id.isEmpty) {
      AppSnackbar.error('Advance Payment', 'Missing booking reference');
      return;
    }
    AdvancePaymentSheet.show(
      bookingId: id,
      totalFare: _totalFareValue,
      onPaid: _confirmAfterAdvance,
      isScheduled: _isScheduled,
    );
  }

  Future<void> _confirmAfterAdvance() async {
    final tss = Get.find<TripStateService>();
    try {
      final res = await _tripsRepo.confirmBooking(controller.bookingId);
      final data = res?['data'];
      final dispatch = (data is Map ? data['dispatchDuration'] : null) ?? res?['dispatchDuration'];
      tss.dispatchSeconds = int.tryParse('$dispatch') ?? 0;
    } catch (_) {}
    tss.dispatchStartAt = DateTime.now();
    _onContinue();
  }

  Future<void> _confirmBooking() async {
    final String id = controller.bookingId;
    if (id.isEmpty) {
      AppSnackbar.error('Confirm Booking', 'Missing booking reference');
      return;
    }
    try {
      isConfirming.value = true;
      final res = await _tripsRepo.confirmBooking(id);
      final data = res?['data'];
      final dispatch = (data is Map ? data['dispatchDuration'] : null) ?? res?['dispatchDuration'];
      final tss = Get.find<TripStateService>();
      tss.dispatchSeconds = int.tryParse('$dispatch') ?? 0;
      tss.dispatchStartAt = DateTime.now();
      _onContinue();
    } on ApiException catch (e) {
      AppSnackbar.error('Confirm Booking', e.message);
    } catch (_) {
      AppSnackbar.error('Confirm Booking', 'Something went wrong');
    } finally {
      isConfirming.value = false;
    }
  }

  void _onContinue() {
    if (Get.isRegistered<VehicleSelectionController>()) {
      Get.find<VehicleSelectionController>().resetState();
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().clearRouteOverlay();
    }

    if (_isScheduled) {
      final tss = Get.find<TripStateService>();
      tss.muteAutoNav(tss.selectedBookingId.value);

      Get.find<HomeController>().currentTab.value = 1;
      Get.find<MyTripsController>().setTab(TripStatus.scheduled);

      AppSnackbar.success("Trip Scheduled", "Your trip has been added to Scheduled Trips");

      Get.offAllNamed(AppRoutes.home);
    } else {
      final String vehicleType = (_args['vehicleType'] ?? '').toString();
      final tripStateService = Get.find<TripStateService>();
      tripStateService.updateRideStage(RideStage.findingDriver, bookingId: tripStateService.selectedBookingId.value);

      AppSnackbar.success("Ride Requested", "Request sent for $vehicleType");

      Get.offNamed(
        AppRoutes.findingDriver,
        arguments: {
          'pickup': _args['pickup'],
          'dropoff': _args['dropoff'],
          'price': _args['price'],
          'vehicleType': vehicleType,
          'source': 'request',
        },
      );
    }
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
              text: 'Review Booking',
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
                  const CustomText(
                    text: 'Review your trip details before confirming your ride.',
                    fontSize: 16,
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

                  if (controller.isRoundTrip) ...[_buildReturnDateCard(), 16.height],

                  _buildPassengerCard(),
                  16.height,

                  _buildFareCard(),
                  16.height,

                  if (_isScheduled) ...[_buildScheduledNotice(), 16.height],

                  _buildTermsCard(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => Container(
                      key: _coachAdvanceKey,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: payAdvance.value ? AppColors.primary : AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primary),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomText(
                                  text: 'Pay Advance',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkSlate,
                                ),
                                const CustomText(
                                  text: 'Pay a portion now, rest after trip',
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: payAdvance.value,
                            onChanged: (val) => payAdvance.value = val,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                            inactiveThumbColor: AppColors.grey400,
                            inactiveTrackColor: AppColors.grey200,
                          ),
                        ],
                      ),
                    ),
                  ),
                  CoachMarkTrigger(
                    storageKey: 'trip_summary_advance_coach',
                    steps: () => [
                      CoachMark(
                        targetKey: _coachAdvanceKey,
                        title: 'Pay advance',
                        description: 'Turn this on to pay part of the fare now and settle the rest after the trip.',
                        holeRadius: 15,
                      ),
                    ],
                  ),
                  16.height,
                  Obx(
                    () => CustomButton(
                      text: isConfirming.value
                          ? 'Confirming...'
                          : (payAdvance.value ? 'Confirm and Pay Advance' : 'Confirm Booking'),
                      onPressed: isConfirming.value ? () {} : (payAdvance.value ? _openAdvanceSheet : _confirmBooking),
                      gradient: AppColors.gradientButton,
                      textColor: AppColors.white,
                    ),
                  ),
                  10.height,
                  Obx(
                    () => payAdvance.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.grey400),
                              6.width,
                              const CustomText(text: 'Secured by Razorpay', fontSize: 10, color: AppColors.grey400),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timelineHeading(icon: Icons.my_location_rounded, color: AppColors.primary, label: 'PICKUP LOCATION'),

                _timelineBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: controller.pickupLocation,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                      if (controller.hasStops) _buildStopsSection(),
                    ],
                  ),
                ),

                _timelineHeading(icon: Icons.place_rounded, color: AppColors.darkSlate, label: 'DESTINATION'),

                Padding(
                  padding: const EdgeInsets.only(left: _railIndent, top: 4),
                  child: CustomText(
                    text: controller.destination,
                    fontSize: 13,
                    textAlign: TextAlign.start,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    maxLines: 3,
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
                  fontSize: 13,
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

  static const double _badgeSize = 32;
  static const double _railIndent = _badgeSize + 12;

  Widget _timelineHeading({required IconData icon, required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: _badgeSize,
          height: _badgeSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        (_railIndent - _badgeSize).width,
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

  Widget _timelineBody({required Widget child}) {
    return Stack(
      children: [
        const Positioned(left: _badgeSize / 2 - 1, top: 0, bottom: 0, width: 2, child: DottedVerticalLine()),
        Padding(
          padding: const EdgeInsets.only(left: _railIndent, top: 6, bottom: 18),
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

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(text: 'PICKUP TIME', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),
          12.height,
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(8)),
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
                    CustomText(
                      text: controller.pickupETA,
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

  Widget _buildReturnDateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.rMd,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.white),
      ),
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

  Widget _buildPassengerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
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
          if (controller.hasPermitCharges) ...[12.height, _buildFareRow('Permit Charges', controller.permitCharges)],
          if (controller.hasDriverAllowance) ...[
            12.height,
            _buildFareRow('Driver Allowance', controller.driverAllowance),
          ],
          if (controller.hasDriverCharges) ...[12.height, _buildFareRow('Driver Charges', controller.driverCharges)],
          if (controller.hasExtraCharges) ...[12.height, _buildFareRow('Extra Charges', controller.extraCharges)],
          if (controller.hasTips) ...[12.height, _buildFareRow('Driver Tip', controller.tipsAmount)],
          if (controller.hasDiscount) ...[
            12.height,
            _buildFareRow('Discount', controller.discountAmount, color: AppColors.red),
          ],
          if (controller.hasAdvance) ...[
            12.height,
            _buildFareRow('Advance Paid', controller.advanceAmount, color: AppColors.red),
          ],
          16.height,
          Divider(color: AppColors.grey200),
          16.height,
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
          15.height,
          _buildFareNote(),
        ],
      ),
    );
  }

  Widget _buildFareNote() {
    return ClipRRect(
      borderRadius: AppRadius.rSm,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.warning),
            Expanded(
              child: Container(
                color: AppColors.grey50,
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.info, size: 20, color: AppColors.warning),
                    ),
                    12.width,
                    const Expanded(
                      child: CustomText(
                        text: 'Final fare may vary based on additional distance travelled and applicable toll charges.',
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
    );
  }

  Widget _buildTermsCard() {
    return Obx(() {
      final doc = terms.value;
      if (doc == null || doc.content.trim().isEmpty) return const SizedBox.shrink();
      final bool expanded = termsExpanded.value;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rMd, boxShadow: AppShadows.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: termsExpanded.toggle,
              borderRadius: AppRadius.rMd,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.info_outline_rounded, size: 17, color: AppColors.primary),
                    ),
                    12.width,
                    Expanded(
                      child: CustomText(
                        text: 'Things to Know',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: AppColors.grey200, height: 1),
                          Html(
                            data: doc.content,
                            style: {
                              'body': Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontFamily: 'Poppins',
                                fontSize: FontSize(12),
                                color: AppColors.slate500,
                                lineHeight: LineHeight.number(1.6),
                              ),
                              'h1': Style(fontSize: FontSize(15), color: AppColors.darkSlate),
                              'h2': Style(fontSize: FontSize(13), color: AppColors.darkSlate),
                              'h3': Style(fontSize: FontSize(12), color: AppColors.darkSlate),
                              'strong': Style(color: AppColors.darkSlate),
                              'a': Style(color: AppColors.primary),
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildScheduledNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
      decoration: const BoxDecoration(color: AppColors.amber50, borderRadius: AppRadius.rMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScheduledArt(),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'Subject to driver availability',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                  textAlign: TextAlign.left,
                ),
                8.height,
                const CustomText(
                  text:
                      'Scheduled bookings are subject to driver availability. Your booking will be offered to nearby drivers at the scheduled time and confirmed once accepted.',
                  fontSize: 10,
                  color: AppColors.slate500,
                  textAlign: TextAlign.left,
                  height: 1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledArt() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: const Icon(Icons.local_taxi, size: 30, color: AppColors.orange),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(Icons.schedule, size: 17, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 14, color: AppColors.slate500),
        CustomText(text: value, fontSize: 14, color: color ?? AppColors.slate500),
      ],
    );
  }
}
