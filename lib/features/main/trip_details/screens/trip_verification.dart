import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_mark_trigger.dart';
import 'package:orange_taxi_customer_app/features/main/chat/widgets/chat_option_sheet.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/badge/unread_badge.dart';
import 'package:orange_taxi_customer_app/features/main/chat/services/chat_unread_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/finding_driver_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/widgets/cancel_ride_bottom_sheet.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/widgets/trip_resume_refresher.dart';
import 'package:url_launcher/url_launcher.dart';

class TripVerificationScreen extends StatefulWidget {
  const TripVerificationScreen({super.key});

  @override
  State<TripVerificationScreen> createState() => _TripVerificationScreenState();
}

class _TripVerificationScreenState extends State<TripVerificationScreen> {
  final TripStateService tripStateService = Get.find<TripStateService>();
  final GlobalKey _coachOtpKey = GlobalKey();
  GoogleMapController? _mapController;

  Timer? _tick;
  // late final DateTime _openedAt;

  bool _framedMap = false;
  bool _showCancelAction = false;

  @override
  void initState() {
    super.initState();
    // _openedAt = DateTime.now();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    if (Get.isRegistered<FindingDriverController>()) {
      Get.find<FindingDriverController>().prewarmTripRoute();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // String get _waitingFor {
  //   final id = tripStateService.selectedBookingId.value;
  //   final start = tripStateService.driverArrivedAt[id] ?? _openedAt;
  //   final secs = DateTime.now().difference(start).inSeconds;
  //   final m = secs ~/ 60;
  //   final s = secs % 60;
  //   return '$m:${s.toString().padLeft(2, '0')}';
  // }

  // double? get _driverMetresAway {
  //   final driver = tripStateService.driverLocation.value;
  //   final pickup = _pickup;
  //   if (driver == null || pickup == null) return null;
  //   return Geolocator.distanceBetween(driver.latitude, driver.longitude, pickup.latitude, pickup.longitude);
  // }

  Future<void> _cancelTrip() async {
    await Get.bottomSheet(
      CancelRideBottomSheet(
        onCancelComplete: () async {
          await Get.to(() => const CancellationSuccessScreen());
        },
      ),
      isScrollControlled: true,
    );
  }

  void _handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  LatLng? get _pickup {
    final t = tripStateService.selectedTrip;
    final lat = t?.pickupLat;
    final lng = t?.pickupLng;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _mapFocus {
    final driver = tripStateService.driverLocation.value;
    if (driver != null) return driver;
    final pickup = _pickup;
    if (pickup != null) return pickup;
    return tripStateService.markers.isNotEmpty ? tripStateService.markers.first.position : null;
  }

  void _frameMapOnce() {
    if (_framedMap || _mapController == null) return;
    final target = _mapFocus;
    if (target == null) return;
    _framedMap = true;
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  void _recenter() {
    final target = _mapFocus;
    if (target != null) _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  Future<void> _applyMapStyle(GoogleMapController c) async {
    try {
      // final style = await rootBundle.loadString('assets/map_style.json');
      // await c.setMapStyle(style);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: TripResumeRefresher(
          label: 'trip-verification',
          onRefreshed: () async {
            _framedMap = false;
            _frameMapOnce();
          },
          child: Obx(() {
            final activeTrip = tripStateService.selectedTrip;

            if ((activeTrip?.driverImage ?? '').trim().isEmpty && (activeTrip?.bookingId ?? '').isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => tripStateService.ensureDriverImage(activeTrip!.bookingId!),
              );
            }

            tripStateService.markers.length;
            tripStateService.driverLocation.value;

            WidgetsBinding.instance.addPostFrameCallback((_) => _frameMapOnce());

            return Stack(
              children: [
                Positioned.fill(child: _buildMap()),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _circleButton(Icons.arrow_back, _handleBack),
                        12.width,
                        Expanded(child: _statusPill()),
                        56.width,
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      60.height,
                      _circleButton(Icons.my_location, _recenter),
                      12.height,
                      _zoomControls(),

                      12.height,
                      InkWell(
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
                ),

                Align(alignment: Alignment.bottomCenter, child: _bottomCard(context, activeTrip)),

                CoachMarkTrigger(
                  storageKey: 'trip_verification_otp_coach',
                  steps: () => [
                    CoachMark(
                      targetKey: _coachOtpKey,
                      title: 'Start trip OTP',
                      description:
                          'Read this code out to the driver once you are seated. The trip only starts after they enter it.',
                      holeRadius: 16,
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final LatLng initial = _pickup ?? const LatLng(11.0168, 76.9558);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initial, zoom: 15),
      onMapCreated: (c) {
        _mapController = c;
        _applyMapStyle(c);
        _frameMapOnce();
      },
      markers: tripStateService.markers.toSet(),
      polylines: const <Polyline>{},
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      padding: const EdgeInsets.only(bottom: 400),
    );
  }

  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
          ),
          8.width,
          const CustomText(
            text: 'Driver arrived',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkSlate,
          ),
          // 6.width,
          // CustomText(text: '·', fontSize: 14, color: AppColors.grey400),
          // 6.width,
          // CustomText(text: _waitingFor, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: AppColors.darkSlate, size: 20),
      ),
    );
  }

  Widget _zoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.darkSlate, size: 20),
            onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
          ),
          Container(width: 20, height: 1, color: AppColors.grey200),
          IconButton(
            icon: const Icon(Icons.remove, color: AppColors.darkSlate, size: 20),
            onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
          ),
        ],
      ),
    );
  }

  Widget _bottomCard(BuildContext context, dynamic activeTrip) {
    final String pin = (activeTrip?.startOtp ?? '----').toString();
    final String rawMethod = (activeTrip?.paymentMethod ?? '').toString().trim();
    final String methodLc = rawMethod.toLowerCase();
    final String payMethod = methodLc == 'upi'
        ? 'Online'
        : rawMethod.isEmpty
        ? 'unknown'
        : rawMethod[0].toUpperCase() + rawMethod.substring(1);
    final IconData payIcon = methodLc.contains('wallet')
        ? Icons.account_balance_wallet_outlined
        : methodLc.contains('cash')
        ? Icons.payments_outlined
        : Icons.account_balance;

    final String address = activeTrip?.destinationLocation ?? 'Destination';
    final String plate = (activeTrip?.plateNumber ?? '-').toString();
    final String vehicleName = (activeTrip?.vehicleModel ?? activeTrip?.vehicleType ?? 'Vehicle').toString();
    final String vehicleType = (activeTrip?.vehicleType ?? '').toString();
    final String vehicleSubtitle = vehicleType == vehicleName ? '' : vehicleType;
    final String rating = (activeTrip?.driverRating ?? 0.0).toStringAsFixed(1);
    final String trips = (activeTrip?.driverTrips ?? '').toString();
    // final double? metresAway = _driverMetresAway;

    // final double? km = (activeTrip?.distanceInKm as num?)?.toDouble();
    // final String? mins = (activeTrip?.duration ?? '').toString().isEmpty ? null : activeTrip.duration.toString();

    // final String tripSizeRaw = [
    //   if (km != null && km > 0) '${km.toStringAsFixed(1)} km',
    //   if (mins != null) mins,
    // ].join(' ● ');

    //     final String tripSize = tripSizeRaw.isEmpty ? '--' : tripSizeRaw;
    //  final double fare = (activeTrip?.customerFinalAmount ?? activeTrip?.totalFare ?? activeTrip?.finalAmount ?? 0)
    //         .toDouble();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarImage(size: 48, url: activeTrip?.driverImage),
                  12.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: activeTrip?.driverName ?? 'Driver',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkSlate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                        4.height,
                        Row(
                          children: [
                            if (rating.isNotEmpty && double.parse(rating) > 0) ...[
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                              4.width,
                              CustomText(
                                text: rating,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkSlate,
                              ),
                            ],
                            if (rating.isNotEmpty &&
                                double.parse(rating) > 0 &&
                                rating.isNotEmpty &&
                                double.parse(rating) > 0) ...[
                              6.width,
                              CustomText(text: '●', fontSize: 13, color: AppColors.grey400),
                            ],
                            if (trips.isNotEmpty && double.parse(trips) > 0) ...[
                              6.width,
                              Flexible(
                                child: CustomText(
                                  text: '$trips trips',
                                  fontSize: 13,
                                  color: AppColors.slate500,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  8.width,
                  GestureDetector(
                    onTap: () async {
                      final phone = activeTrip?.driverPhone ?? '';
                      if (phone.isNotEmpty) {
                        await launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);
                      }
                    },
                    child: _actionCircle(Icons.phone_outlined),
                  ),
                  8.width,
                  GestureDetector(
                    onTap: () => ChatOptionSheet.show(),
                    child: Obx(() {
                      final int unread = Get.find<ChatUnreadService>().total.value;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _actionCircle(Icons.forum_outlined),
                          if (unread > 0) Positioned(right: -2, top: -2, child: UnreadBadge(count: unread)),
                        ],
                      );
                    }),
                  ),
                ],
              ),

              14.height,

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.directions_car_filled_outlined, size: 22, color: AppColors.darkSlate),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: vehicleName,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                          if (vehicleSubtitle.isNotEmpty) ...[
                            2.height,
                            CustomText(
                              text: vehicleSubtitle,
                              fontSize: 12,
                              color: AppColors.slate500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ],
                      ),
                    ),
                    10.width,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
                      child: CustomText(
                        text: plate,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.charcoal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              14.height,

              Container(
                key: _coachOtpKey,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: CustomText(
                            text: 'START OTP',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey500,
                            letterSpacing: 1.2,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    4.height,
                    CustomText(
                      text: pin,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 10,
                      textAlign: TextAlign.start,
                    ),
                    4.height,
                    const CustomText(
                      text: 'Give this to the driver only after you are seated',
                      fontSize: 11,
                      color: AppColors.slate500,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),

              14.height,

              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _factLabel('DESTINATION'),
                          4.height,
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 15, color: AppColors.primary),
                              6.width,
                              Expanded(
                                child: CustomText(
                                  text: address,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkSlate,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                          4.height,
                          // _factLabel('Distance and Duration'),
                          // 7.height,
                          // Row(
                          //   children: [
                          //     22.width,
                          //     Expanded(
                          //       child: CustomText(
                          //         text: tripSize,
                          //         fontSize: 13,
                          //         fontWeight: FontWeight.w100,
                          //         color: AppColors.darkSlate,
                          //         maxLines: 1,
                          //         overflow: TextOverflow.ellipsis,
                          //         textAlign: TextAlign.start,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                    12.width,
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _factLabel('PAYMENT METHOD'),
                          4.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(payIcon, size: 15, color: AppColors.primary),
                              6.width,
                              Flexible(
                                child: CustomText(
                                  text: payMethod,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkSlate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // 7.height,
                          // _factLabel('ESTIMATED FARE'),

                          // 4.height,
                          // CustomText(
                          //   text: fare > 0 ? '₹${fare.toStringAsFixed(0)}' : '--',
                          //   fontSize: 15,
                          //   fontWeight: FontWeight.w100,
                          //   color: fare > 0 ? AppColors.darkSlate : AppColors.grey400,
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              18.height,

              _cancelReveal(),
              20.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _cancelReveal() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showCancelAction = !_showCancelAction),
      onVerticalDragEnd: (details) {
        final double velocity = details.primaryVelocity ?? 0;
        if (velocity < -80) setState(() => _showCancelAction = true);
        if (velocity > 80) setState(() => _showCancelAction = false);
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _showCancelAction ? 0.5 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.grey400),
                  ),
                  6.width,
                  const CustomText(
                    text: 'Manage ride',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                  ),
                ],
              ),
              if (_showCancelAction) ...[
                12.height,
                CustomButton(onPressed: _cancelTrip, text: 'Cancel ride', textColor: AppColors.black),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _factLabel(String text) {
    return CustomText(
      text: text,
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: AppColors.grey400,
      letterSpacing: 0.8,
    );
  }

  Widget _actionCircle(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 20, color: AppColors.charcoal),
    );
  }
}
