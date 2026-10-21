import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_textfield/custom_textfield.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/models/trip_details_model.dart';
import '../controllers/my_trips_controller.dart';

class MyTripsScreen extends GetView<MyTripsController> {
  const MyTripsScreen({super.key});

  void _showFilterDialog() {
    final TextEditingController placeController = TextEditingController(text: controller.selectedFilterPlace.value);
    TripPeriod selectedPeriod = controller.selectedPeriod.value;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
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

                const CustomText(text: 'Filter Trips', fontSize: 18, fontWeight: FontWeight.bold),

                20.height,

                const CustomText(text: 'Period', fontSize: 12, fontWeight: FontWeight.w600),

                8.height,

                DropdownButtonFormField<TripPeriod>(
                  initialValue: selectedPeriod,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey600),
                  dropdownColor: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: TripPeriod.values
                      .map(
                        (period) => DropdownMenuItem<TripPeriod>(
                          value: period,
                          child: CustomText(
                            text: period.label,
                            fontSize: 14,
                            color: AppColors.darkSlate,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedPeriod = value);
                  },
                ),

                16.height,
                const CustomText(text: 'Place', fontSize: 12, fontWeight: FontWeight.w600),
                8.height,
                CustomTextField(controller: placeController, label: 'Search location'),
                24.height,

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Reset',
                        gradient: AppColors.disabledGradient,
                        onPressed: () {
                          placeController.clear();
                          setState(() => selectedPeriod = TripPeriod.all);
                          controller.clearFilters();
                          Get.back();
                        },
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: CustomButton(
                        text: 'Apply',
                        gradient: AppColors.gradientButton,
                        textColor: AppColors.white,
                        onPressed: () {
                          controller.setPeriod(selectedPeriod);
                          controller.applyFilters(placeController.text.trim());
                          Get.back();
                        },
                      ),
                    ),
                  ],
                ),

                20.height,
              ],
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        leading: SizedBox.shrink(),
        title: const CustomText(text: 'My Bookings', fontSize: 18, fontWeight: FontWeight.bold),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.grey200,
              child: IconButton(
                icon: const Icon(Icons.tune, color: AppColors.black, size: 20),
                onPressed: _showFilterDialog,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          20.height,
          _buildTabs(),
          20.height,
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 90),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [Shimmer(child: Column(children: List.generate(4, (_) => const TripCardSkeleton())))],
                );
              }

              Future<void> refresh() => controller.fetchTrips(controller.selectedTab.value);

              if (controller.filteredTrips.isEmpty) {
                return AppRefreshIndicator(
                  onRefresh: refresh,
                  slivers: const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CustomText(text: 'No trips found')),
                    ),
                  ],
                );
              }

              return AppRefreshIndicator(
                onRefresh: refresh,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    sliver: SliverList.builder(
                      itemCount: controller.filteredTrips.length,
                      itemBuilder: (context, index) => _buildTripCard(controller.filteredTrips[index]),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(50)),
      child: Row(
        children: [
          _buildTabItem('Completed', TripStatus.completed),
          _buildTabItem('Scheduled', TripStatus.scheduled),
          _buildTabItem('Cancelled', TripStatus.cancelled),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, TripStatus status) {
    return Expanded(
      child: Obx(() {
        bool isSelected = controller.selectedTab.value == status;

        return GestureDetector(
          onTap: () => controller.setTab(status),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.gradientButton : AppColors.disabledGradient,
              borderRadius: BorderRadius.circular(50),
            ),
            child: CustomText(
              text: title,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.white : AppColors.black,
            ),
          ),
        );
      }),
    );
  }

  String formatAmount(dynamic amount) {
    return (double.tryParse(amount?.toString() ?? '') ?? 0).toStringAsFixed(2);
  }

  dynamic _cardAmount(Map<String, dynamic> trip) {
    final String status = trip['status']?.toString().toLowerCase() ?? '';
    final dynamic after = trip['afterTripBreakdowns'];
    if (status == 'completed' && after is Map && after['customerFareBreakDown'] is Map) {
      final cust = after['customerFareBreakDown'];
      final fin = cust['customerFinalAmount'] ?? cust['finalAmount'];
      if (fin != null) return fin;
    }
    return trip['finalAmount'];
  }

  String formatScheduledDate(String? date) {
    if (date == null || date.isEmpty) return 'Date unavailable';
    final parsedDate = DateTime.tryParse(date)?.toLocal();
    if (parsedDate == null) return 'Date unavailable';
    return DateFormat('dd MMM yyyy • hh:mm a').format(parsedDate);
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final String status = trip['status']?.toString().toLowerCase() ?? '';
    final String paymentStatus = trip['paymentStatus']?.toString().toLowerCase() ?? '';
    final String bookingId = (trip['bookingId'] ?? trip['_id'] ?? '').toString();

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (status == 'completed' && paymentStatus == 'pending') {
      statusText = 'PAYMENT PENDING';
      statusColor = AppColors.orange;
      statusIcon = Icons.payment;
    } else if (status == 'completed') {
      statusText = 'COMPLETED';
      statusColor = AppColors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'cancelled') {
      statusText = 'CANCELLED';
      statusColor = AppColors.red;
      statusIcon = Icons.cancel;
    } else {
      statusText = status.toUpperCase();
      statusColor = AppColors.primary;
      statusIcon = Icons.access_time;
    }

    final String dateText = formatScheduledDate(trip['scheduledAt'] ?? trip['createdAt']);

    return GestureDetector(
      onTap: () {
        if (status == 'booking accepted' || status == 'pickup arrived' || status == 'started') {
          controller.resumeTrip(trip);
        } else if (status == 'completed' && paymentStatus == 'pending') {
          controller.resumeTrip(trip);
        } else {
          _navigateToTripDetails(trip);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.grey400),
                      6.width,
                      Flexible(
                        child: CustomText(
                          text: bookingId.isEmpty ? 'Booking' : bookingId,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey600,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                8.width,
                CustomText(
                  text: '₹${formatAmount(_cardAmount(trip))}',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                ),
              ],
            ),
            12.height,
            Divider(color: AppColors.grey100, height: 1),
            14.height,

            _routeTimeline(trip['pickupAddress'] ?? 'Unknown location', trip['dropoffAddress'] ?? 'Unknown location'),
            14.height,
            Divider(color: AppColors.grey100, height: 1),
            12.height,

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.grey400),
                      6.width,
                      Flexible(
                        child: CustomText(
                          text: dateText,
                          fontSize: 12,
                          color: AppColors.grey500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      4.width,
                      CustomText(text: statusText, fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ],
                  ),
                ),

                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.grey600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeTimeline(String pickup, String dropoff) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _pointBadge(Icons.my_location_rounded, AppColors.primary),
              1.height,
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(width: 2, child: DottedVerticalLine()),
                ),
              ),
              _pointBadge(Icons.place_rounded, AppColors.darkSlate),
            ],
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: CustomText(
                    text: pickup,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                16.height,
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: CustomText(
                    text: dropoff,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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

  void _navigateToTripDetails(Map<String, dynamic> trip) {
    final tripStateService = Get.find<TripStateService>();
    final bookingId = trip['bookingId'] ?? trip['_id'] ?? '';

    final enquiry = trip['enquiryData'] is Map ? trip['enquiryData'] as Map : const {};
    final firstVehicle = (enquiry['vehicles'] is List && (enquiry['vehicles'] as List).isNotEmpty)
        ? (enquiry['vehicles'] as List).first as Map
        : const {};

    double firstDistance(List<dynamic> vals) {
      for (final v in vals) {
        final d = double.tryParse(v?.toString().replaceAll('NaN', '') ?? '');
        if (d != null && d > 0) return d;
      }
      return 0.0;
    }

    final double distanceKm = firstDistance([
      trip['afterTripBreakdowns']?['fare']?['distance'],
      enquiry['distance_km'],
      trip['tripCompletedDistance'],
      trip['distance'],
      trip['distanceKm'],
    ]);

    final int durationMins =
        int.tryParse(
          (trip['tripCompletedDuration'] ??
                  enquiry['duration_mins'] ??
                  trip['durationMinutes'] ??
                  trip['duration'] ??
                  '0')
              .toString(),
        ) ??
        0;

    final dynamic vehicleObj = trip['vehicle'];
    final String vehicleType =
        (trip['vehicleType'] ??
                firstVehicle['vehicle_type'] ??
                (vehicleObj is Map ? (vehicleObj['type'] ?? vehicleObj['vehicle_type']) : vehicleObj) ??
                'Unknown')
            .toString();
    final String vehicleModel =
        (trip['vehicleName'] ??
                firstVehicle['name'] ??
                (vehicleObj is Map ? vehicleObj['modelName'] : null) ??
                trip['vehicleModel'] ??
                vehicleType)
            .toString();

    final String status = trip['status']?.toString().toLowerCase() ?? '';
    final dynamic after = trip['afterTripBreakdowns'];
    final Map afterCust = (status == 'completed' && after is Map && after['customerFareBreakDown'] is Map)
        ? after['customerFareBreakDown'] as Map
        : const {};
    final Map fare = afterCust.isNotEmpty ? afterCust : controller.fareBreakdown(trip);
    double fareD(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    final dynamic breakdownTotal = fare['customerFinalAmount'] ?? fare['finalAmount'];
    final double finalAmount = breakdownTotal != null
        ? fareD(breakdownTotal)
        : (double.tryParse(trip['finalAmount']?.toString() ?? '0') ?? 0.0);

    final tripDetailsModel = TripDetailsModel(
      bookingId: bookingId,
      pickupLocation: trip['pickupAddress'] ?? 'Unknown',
      destinationLocation: trip['dropoffAddress'] ?? 'Unknown',
      pickupDateTime: DateTime.tryParse((trip['scheduledAt'] ?? trip['createdAt'] ?? '').toString()),
      totalFare: finalAmount,
      finalAmount: finalAmount,
      customerFinalAmount: fare['customerFinalAmount'] != null ? fareD(fare['customerFinalAmount']) : null,
      tripCompletedFinalAmount: double.tryParse(
        ((trip['afterTripBreakdowns']?['customerFareBreakDown']?['customerFinalAmount']) ??
                    (trip['afterTripBreakdowns']?['customerFareBreakDown']?['finalAmount']) ??
                    trip['tripCompletedFinalAmount'])
                ?.toString() ??
            '',
      ),
      status: trip['status'],
      cancellationReason: trip['cancellationReason'] ?? trip['cancelReason'] ?? trip['reason'],
      paymentStatus: trip['paymentStatus'],
      paymentMethod: trip['paymentMethod'],
      distanceInKm: distanceKm,
      duration: controller.formatDuration(durationMins),
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      plateNumber: vehicleObj is Map ? vehicleObj['number']?.toString() : null,
      estimatedFare: fareD(fare['estimatedFare']),
      pricePerKm: double.tryParse(trip['pricePerKm']?.toString() ?? ''),
      serviceTax: fareD(fare['serviceTax']),
      tollAmount: fareD(fare['tollAmount']),
      discountAmount: fareD(fare['discountAmount']),
      driverAllowance: fareD(fare['driverAllowance']),
      totalDriverCharges: fareD(fare['totalDriverCharges']),
      totalExtraCharges: fareD(fare['totalExtraCharges']),
      permitCharges: fareD(fare['permitCharges']),
      tipsAmount: fareD(fare['tipsAmount']),
      advanceAmount: fare['advanceAmount'] != null ? fareD(fare['advanceAmount']) : fareD(trip['advancePaymentAmount']),
      stops: TripDetailsModel.stopsFrom(trip['stops'] ?? trip['enquiryData']?['stops']),
    );

    final String advStatus = (trip['advancePaymentStatus'] ?? '').toString().toLowerCase();
    final bool advancePaid = advStatus == 'paid' || advStatus == 'success' || advStatus == 'completed';
    final bool canAct = status != 'completed' && status != 'cancelled';
    final hadTrip = tripStateService.activeTrips.containsKey(bookingId);
    final prevSelected = tripStateService.selectedBookingId.value;

    tripStateService.suppressAutoNav = true;
    if (hadTrip) {
      tripStateService.updateTripDetails(tripDetailsModel, bookingId: bookingId);
    } else {
      tripStateService.activeTrips[bookingId] = tripDetailsModel;
    }
    tripStateService.selectedBookingId.value = bookingId;
    tripStateService.suppressAutoNav = false;

    Get.toNamed(
      AppRoutes.tripDetails,
      arguments: {
        'canAct': canAct,
        'advancePaid': advancePaid,
        'bookingId': bookingId,
        'rawBookingId': trip['bookingId']?.toString() ?? '',
        'rawId': trip['_id']?.toString() ?? '',
        'totalFare': finalAmount,
      },
    )?.then((_) {
      if (!hadTrip) {
        tripStateService.suppressAutoNav = true;
        tripStateService.activeTrips.remove(bookingId);
        tripStateService.selectedBookingId.value = tripStateService.activeTrips.containsKey(prevSelected)
            ? prevSelected
            : (tripStateService.activeTrips.isNotEmpty ? tripStateService.activeTrips.keys.first : '');
        tripStateService.suppressAutoNav = false;
      }
    });
  }
}
