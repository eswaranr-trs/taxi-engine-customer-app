import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class TripFinishedScreen extends StatefulWidget {
  const TripFinishedScreen({super.key});

  @override
  State<TripFinishedScreen> createState() => _TripFinishedScreenState();
}

class _TripFinishedScreenState extends State<TripFinishedScreen> {
  final TripStateService _tripStateService = Get.find<TripStateService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: const CustomText(
          text: 'Trip Finished',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkSlate,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Obx(() {
          final trip = _tripStateService.selectedTrip;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
              ),
              24.height,
              const CustomText(
                text: 'Arrived Safely!',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
              8.height,
              const CustomText(
                text: 'Thank you for traveling with Orange Taxi. Your journey is complete.',
                fontSize: 14,
                color: AppColors.slate500,
                textAlign: TextAlign.center,
              ),
              32.height,
              _buildFareDetailsCard(trip),
              16.height,
              _buildRouteCard(trip),

              20.height,
            ],
          );
        }),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  double? _totalFareOf(TripDetailsModel? trip) =>
      trip?.customerFinalAmount ?? trip?.tripCompletedFinalAmount ?? trip?.totalFare ?? trip?.finalAmount;

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return CustomText(text: text, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey400);
  }

  Widget _buildFareDetailsCard(TripDetailsModel? trip) {
    final double? totalFareVal = _totalFareOf(trip);
    final String totalFare = totalFareVal != null ? _money(totalFareVal) : '₹0';

    final double? distanceVal = (trip?.tripCompletedDistance != null && trip!.tripCompletedDistance! > 0)
        ? trip.tripCompletedDistance
        : (trip?.distanceInKm != null && trip!.distanceInKm! > 0)
        ? trip.distanceInKm
        : null;
    final String distance = distanceVal != null
        ? '${distanceVal.toStringAsFixed(1)} km'
        : (trip?.distanceLeft?.isNotEmpty ?? false)
        ? trip!.distanceLeft!
        : '0 km';

    final String duration = (trip?.duration?.isNotEmpty ?? false) ? trip!.duration! : '0 min';

    // final bool paid = TripStateService.isPaidStatus(trip?.paymentStatus);
    // final double advance = trip?.advanceAmount ?? 0;
    // final double? due = (!paid && totalFareVal != null && advance > 0) ? (totalFareVal - advance) : null;

    // final List<_FareLine> lines = _breakdownLines(trip);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TOTAL FARE'),
          const SizedBox(height: 4),
          CustomText(text: totalFare, fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
          // if (due != null) ...[
          //   6.height,
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: AppColors.primary.withValues(alpha: 0.1),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: CustomText(
          //       text: 'To pay now ${_money(due < 0 ? 0 : due)}  ·  ${_money(advance)} paid in advance',
          //       fontSize: 12,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.primary,
          //     ),
          //   ),
          // // ],
          // const SizedBox(height: 20),
          10.height,
          const Divider(color: AppColors.grey100, height: 1),
          20.height,
          Row(
            children: [
              Expanded(child: _metric(Icons.location_on_outlined, 'DISTANCE', distance)),
              Container(width: 1, height: 30, color: AppColors.grey100),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _metric(Icons.access_time, 'DURATION', duration),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        8.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: label, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),
              4.height,
              CustomText(
                text: value,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(TripDetailsModel? trip) {
    final String pickup = trip?.pickupLocation?.trim().isNotEmpty ?? false ? trip!.pickupLocation! : 'Pickup';
    final String drop = trip?.destinationLocation?.trim().isNotEmpty ?? false
        ? trip!.destinationLocation!
        : 'Destination';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('YOUR ROUTE'),
          16.height,
          _routeRow(
            icon: Icons.my_location_rounded,
            color: AppColors.primary,
            label: 'PICKUP',
            value: pickup,
            lineBelow: true,
          ),
          _routeRow(
            icon: Icons.place_rounded,
            color: AppColors.darkSlate,
            label: 'DESTINATION',
            value: drop,
            lineBelow: false,
          ),
        ],
      ),
    );
  }

  static const double _badgeSize = 20;

  Widget _pointBadge(IconData icon, Color color) {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _routeRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool lineBelow,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _pointBadge(icon, color),
              if (lineBelow)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(width: 2, child: DottedVerticalLine()),
                  ),
                ),
            ],
          ),
          14.width,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: lineBelow ? 14 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: label, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey400),
                  4.height,
                  CustomText(
                    text: value,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Obx(() {
      final bool paid = TripStateService.isPaidStatus(_tripStateService.selectedTrip?.paymentStatus);
      return Container(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
        decoration: const BoxDecoration(color: AppColors.backgroundBeige),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.gradientButton),
            child: ElevatedButton(
              onPressed: () {
                if (paid) {
                  Get.toNamed(AppRoutes.rateTrip);
                } else {
                  _tripStateService.updateRideStage(RideStage.payment);
                  Get.toNamed(AppRoutes.paymentScreen);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.transparent,
                shadowColor: AppColors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: paid ? 'Continue' : 'Continue to Payment',
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
    });
  }
}
