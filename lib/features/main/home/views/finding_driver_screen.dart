import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/features/main/chat/widgets/chat_option_sheet.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/badge/unread_badge.dart';
import 'package:orange_taxi_customer_app/features/main/chat/services/chat_unread_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/finding_driver_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/widgets/cancel_ride_bottom_sheet.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_mark_trigger.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/widgets/trip_resume_refresher.dart';

class FindingDriverScreen extends GetView<FindingDriverController> {
  const FindingDriverScreen({super.key});

  static final GlobalKey _coachRecenterKey = GlobalKey();
  static final GlobalKey _coachSosKey = GlobalKey();
  static final GlobalKey _coachRouteKey = GlobalKey();
  static final GlobalKey _coachManageKey = GlobalKey();
  static final GlobalKey _coachDriverKey = GlobalKey();
  static final GlobalKey _coachEtaKey = GlobalKey();
  static final GlobalKey _coachCallKey = GlobalKey();
  static final GlobalKey _coachChatKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.handleBack();
      },
      child: Scaffold(
        body: TripResumeRefresher(
          label: 'finding-driver',
          onRefreshed: () async => controller.refitPreTripCamera(),
          child: Stack(
            children: [
              Obx(
                () => GoogleMap(
                  initialCameraPosition: const CameraPosition(target: LatLng(11.0168, 76.9558), zoom: 14),
                  onMapCreated: controller.onMapCreated,
                  markers: controller.isDriverFound.value
                      ? controller.markers.where((m) => m.markerId.value != 'destination').toSet()
                      : controller.nearbyDriverMarkers.toSet(),
                  polylines: controller.isDriverFound.value ? controller.polylines.toSet() : const {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  padding: EdgeInsets.only(bottom: 200),
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.black),
                          onPressed: controller.handleBack,
                        ),
                      ),
                      Column(
                        children: [
                          60.height,
                          CircleAvatar(
                            key: _coachRecenterKey,
                            backgroundColor: AppColors.white,
                            child: IconButton(
                              icon: const Icon(Icons.my_location, color: AppColors.black),
                              onPressed: () => controller.centerOnUser(),
                            ),
                          ),
                          12.height,
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add, color: AppColors.black),
                                  onPressed: () => controller.zoomIn(),
                                ),
                                Container(width: 20, height: 1, color: AppColors.grey300),
                                IconButton(
                                  icon: const Icon(Icons.remove, color: AppColors.black),
                                  onPressed: () => controller.zoomOut(),
                                ),
                              ],
                            ),
                          ),
                          12.height,
                          InkWell(
                            key: _coachSosKey,
                            onTap: () {
                              Get.toNamed(AppRoutes.sos);
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              height: 45,
                              width: 45,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(image: AssetImage("assets/images/sos.png"), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Obx(() {
                if (!controller.isDriverFound.value) return const SizedBox.shrink();
                return SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                            12.width,
                            CustomText(
                              text: controller.driverDistance.value.isNotEmpty
                                  ? 'Driver ${controller.driverDistance.value}'
                                  : 'Driver is on the way',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkSlate,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  child: controller.isDriverFound.value
                      ? _buildDriverFoundContent()
                      : _buildFindingDriverContent(context),
                ),
              ),

              CoachMarkTrigger(storageKey: 'finding_driver_coach', steps: _coachSteps),
              Obx(
                () => controller.isDriverFound.value
                    ? CoachMarkTrigger(storageKey: 'driver_found_coach', steps: _driverFoundCoachSteps)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double calculateSheetSize(String pickup, String dropoff) {
    final totalLength = pickup.length + dropoff.length;

    if (totalLength > 250) {
      return 0.72;
    } else if (totalLength > 150) {
      return 0.66;
    }

    return 0.60;
  }

  Widget _buildFindingDriverContent(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
        decoration: const BoxDecoration(
          color: AppColors.backgroundBeige,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + media.padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: CustomText(
                  text: 'Finding your ride',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkSlate,
                ),
              ),
              8.height,
              Center(child: _RotatingStatusText(seconds: controller.apiProgress.value)),
              20.height,
              _buildProgressBar(),
              24.height,
              Obx(() {
                final tripStateService = Get.find<TripStateService>();
                tripStateService.activeTrips.length;
                tripStateService.selectedBookingId.value;

                final activeTrip = tripStateService.selectedTrip;
                final stops = tripStateService.lastBookingStops;
                final String pickup = activeTrip?.pickupLocation ?? controller.pickup.value;
                final String dropoff = activeTrip?.destinationLocation ?? controller.dropoff.value;

                return Container(
                  key: _coachRouteKey,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _routePoint(
                        icon: Icons.my_location_rounded,
                        color: AppColors.primary,
                        label: 'PICKUP',
                        address: pickup,
                        lineBelow: true,
                      ),
                      if (stops.isNotEmpty && tripStateService.selectedLeg < 2) _stopsRail(stops),
                      _routePoint(
                        icon: Icons.place_rounded,
                        color: AppColors.darkSlate,
                        label: 'DESTINATION',
                        address: dropoff,
                        lineBelow: false,
                      ),
                    ],
                  ),
                );
              }),
              18.height,
              _cancelReveal(key: _coachManageKey),
            ],
          ),
        ),
      ),
    );
  }

  static const double _badgeSize = 18;

  Widget _pointBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.8),
        boxShadow: AppShadows.lg,
      ),
      child: Icon(icon, size: 13, color: AppColors.white),
    );
  }

  Widget _routePoint({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
    required bool lineBelow,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _pointBadge(icon, color),
              if (lineBelow) const Expanded(child: SizedBox(width: 2, child: DottedVerticalLine())),
            ],
          ),
          14.width,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: label,
                    fontSize: 10,
                    color: AppColors.grey400,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                  3.height,
                  CustomText(
                    text: address,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkSlate,
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

  Widget _stopsRail(List<Map<String, dynamic>> stops) {
    return Stack(
      children: [
        const Positioned(left: _badgeSize / 2 - 1, top: 0, bottom: 0, width: 2, child: DottedVerticalLine()),
        Padding(
          padding: const EdgeInsets.only(left: _badgeSize + 14, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: controller.showStops.toggle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: '${stops.length} ${stops.length > 1 ? 'stops' : 'stop'}',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                    2.width,
                    Icon(
                      controller.showStops.value ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.orange,
                    ),
                  ],
                ),
              ),
              if (controller.showStops.value)
                ...stops.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                          child: Center(
                            child: CustomText(
                              text: '${e.key + 1}',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: CustomText(
                            text:
                                (e.value['mainText'] ??
                                        e.value['address'] ??
                                        e.value['secondaryText'] ??
                                        'Stop ${e.key + 1}')
                                    .toString(),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey700,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _primaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Gradient? gradient,
    int badge = 0,
  }) {
    const Color foreground = AppColors.darkSlate;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? AppColors.grey100 : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: foreground),
                8.width,
                CustomText(text: label, fontSize: 15, fontWeight: FontWeight.w600, color: foreground),
              ],
            ),
          ),
          if (badge > 0) Positioned(right: -2, top: -2, child: UnreadBadge(count: badge)),
        ],
      ),
    );
  }

  Widget _cancelReveal({Key? key}) {
    return Obx(() {
      final bool open = controller.showCancelAction.value;
      return GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: controller.showCancelAction.toggle,
        onVerticalDragEnd: (details) {
          final double velocity = details.primaryVelocity ?? 0;
          if (velocity < -80) controller.showCancelAction.value = true;
          if (velocity > 80) controller.showCancelAction.value = false;
        },
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.grey400),
                  ),
                  6.width,
                  CustomText(text: 'Manage ride', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500),
                ],
              ),
              if (open) ...[12.height, _cancelRideButton()],
            ],
          ),
        ),
      );
    });
  }

  Widget _cancelRideButton() {
    return CustomButton(
      text: 'Cancel Ride',
      onPressed: () async {
        await Get.bottomSheet(
          CancelRideBottomSheet(
            onCancelComplete: () async {
              await Get.to(() => const CancellationSuccessScreen());
            },
          ),
          isScrollControlled: true,
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Obx(() {
      final double progress = controller.apiProgress.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  return SizedBox(
                    height: 24,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Container(height: 6, width: double.infinity, color: AppColors.grey200),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(gradient: AppColors.gradientButton),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: (width * value - 12).clamp(0.0, width - 24),
                          top: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_taxi, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildDriverFoundContent() {
    final driver = controller.driverDetails;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 20, offset: Offset(0, -5))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  14.height,
                  Row(
                    key: _coachDriverKey,
                    children: [
                      Stack(children: [AvatarImage(size: 64, url: driver['image']?.toString())]),

                      12.width,

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                text: driver['name'],
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkSlate,
                              ),
                            ),

                            2.height,

                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: AppColors.primary),

                                4.width,
                                driver['rating'] != "0" && driver['rating'] != "0.0"
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: CustomText(
                                          text: '${driver['rating']}',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkSlate,
                                        ),
                                      )
                                    : SizedBox.shrink(),

                                6.width,
                                driver['rating'] != "0" && driver['rating'] != "0.0" && driver['trips'] != "0"
                                    ? Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.grey300),
                                      )
                                    : SizedBox.shrink(),

                                6.width,
                                driver['trips'] == "0"
                                    ? SizedBox.shrink()
                                    : Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: CustomText(
                                            text:
                                                '${driver['trips']} ${int.parse(driver['trips']) > 1 ? 'trips' : 'trip'}',
                                            fontSize: 14,
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      8.width,

                      Column(
                        key: _coachEtaKey,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            text: 'ARRIVING IN',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey400,
                          ),

                          2.height,

                          SizedBox(
                            width: 70,
                            child: Obx(
                              () => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: CustomText(
                                  text: controller.driverEta.value.isNotEmpty
                                      ? controller.driverEta.value
                                      : (driver['arrivalTime'] ?? '—'),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  18.height,

                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundBeige,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.directions_car, color: AppColors.slate500),
                        ),

                        12.width,

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: CustomText(
                                  text: driver['vehicleName'],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkSlate,
                                ),
                              ),

                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: CustomText(text: driver['vehicleType'], fontSize: 12, color: AppColors.grey500),
                              ),
                            ],
                          ),
                        ),

                        8.width,

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundBeige,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: CustomText(
                              text: driver['plateNumber'],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  18.height,

                  Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: _coachCallKey,
                          child: _primaryAction(
                            icon: Icons.phone_outlined,
                            label: 'Call',
                            gradient: AppColors.gradientButton,
                            onTap: () => controller.openDialer(),
                          ),
                        ),
                      ),

                      10.width,

                      Expanded(
                        child: KeyedSubtree(
                          key: _coachChatKey,
                          child: Obx(() {
                            final int unread = Get.find<ChatUnreadService>().total.value;
                            return _primaryAction(
                              icon: Icons.forum_outlined,
                              label: 'Chat',
                              badge: unread,
                              onTap: () => ChatOptionSheet.show(),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  14.height,

                  _cancelReveal(),
                  20.height,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<CoachMark> _coachSteps() => [
  CoachMark(
    targetKey: FindingDriverScreen._coachRouteKey,
    title: 'Your booking',
    description: 'Pickup, stops and destination for the ride you just booked. Tap the stop count to expand it.',
    holeRadius: 20,
  ),
  CoachMark(
    targetKey: FindingDriverScreen._coachRecenterKey,
    title: 'Recenter map',
    description: 'Snaps the map back to your location so you can see drivers around you.',
    holeRadius: 24,
  ),
  CoachMark(
    targetKey: FindingDriverScreen._coachSosKey,
    title: 'Emergency SOS',
    description: 'Tap any time during the ride to raise an SOS alert with support.',
    holeRadius: 20,
  ),
  CoachMark(
    targetKey: FindingDriverScreen._coachManageKey,
    title: 'Manage ride',
    description: 'Tap to expand and manage your ride.',
    holeRadius: 16,
  ),
];

List<CoachMark> _driverFoundCoachSteps() => [
  CoachMark(
    targetKey: FindingDriverScreen._coachDriverKey,
    title: 'Driver details',
    description: 'Who is picking you up — name, rating and how many trips they have completed.',
    holeRadius: 16,
  ),
  CoachMark(
    targetKey: FindingDriverScreen._coachEtaKey,
    title: 'Arriving in',
    description: 'Live estimate of how long the driver takes to reach your pickup point.',
    holeRadius: 12,
  ),
  CoachMark(
    targetKey: FindingDriverScreen._coachCallKey,
    title: 'Call the driver',
    description: 'Dial the driver directly to guide them to your exact spot.',
    holeRadius: 16,
  ),
  CoachMark(
    targetKey: FindingDriverScreen._coachChatKey,
    title: 'Chat',
    description: 'Message the driver or support. The badge shows unread replies.',
    holeRadius: 16,
  ),
];

class _RotatingStatusText extends StatefulWidget {
  const _RotatingStatusText({required this.seconds});
  final double seconds;

  @override
  State<_RotatingStatusText> createState() => _RotatingStatusTextState();
}

class _RotatingStatusTextState extends State<_RotatingStatusText> {
  static const List<String> _messages = [
    'Searching nearby drivers...',
    'Notifying nearby drivers...',
    'Connecting you to the best ride...',
    'Almost there...',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final int intervalMs = (widget.seconds * 1000).clamp(2000, 6000).toInt();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: CustomText(
        key: ValueKey<int>(_index),
        text: _messages[_index],
        fontSize: 14,
        color: AppColors.grey500,
        textAlign: TextAlign.center,
      ),
    );
  }
}
