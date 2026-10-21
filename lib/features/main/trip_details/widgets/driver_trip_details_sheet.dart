import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/controllers/trip_distance_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_share_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class DriverDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> driverData;
  final VoidCallback? onTripDetails;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final ValueChanged<double>? onExtent;

  const DriverDetailBottomSheet({
    super.key,
    required this.driverData,
    this.onTripDetails,
    this.onCall,
    this.onMessage,
    this.onExtent,
  });

  @override
  State<DriverDetailBottomSheet> createState() => _DriverDetailBottomSheetState();
}

class _DriverDetailBottomSheetState extends State<DriverDetailBottomSheet> {
  static const double _baseSheetSpace = 24;
  static const double _minSheetExtent = 0.25;
  static const double _maxSheetExtent = 0.94;

  double _extraSheetSpace = _baseSheetSpace;

  static const String _coachKey = 'trip_in_progress_sheet';

  final RxBool _endingTrip = false.obs;
  final RxBool _startingReturn = false.obs;
  final RxDouble _extent = 0.65.obs;
  final RxInt _haltTick = 0.obs;
  final GlobalKey _contentKey = GlobalKey();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  Timer? _haltTimer;
  Timer? _coachTimer;
  double _screenHeight = 0;

  final GlobalKey _etaCoachKey = GlobalKey();
  final GlobalKey _distanceCoachKey = GlobalKey();
  final GlobalKey _otpCoachKey = GlobalKey();
  final GlobalKey _shareCoachKey = GlobalKey();
  final GlobalKey _endTripCoachKey = GlobalKey();
  final GlobalKey _returnTripCoachKey = GlobalKey();
  final GlobalKey _detailsCoachKey = GlobalKey();

  Map<String, dynamic> get driverData => widget.driverData;

  @override
  void initState() {
    super.initState();
    _coachTimer = Timer(const Duration(milliseconds: 1200), _maybeShowCoachMarks);
  }

  @override
  void dispose() {
    _coachTimer?.cancel();
    if (CoachMarks.isVisible) CoachMarks.dismiss();
    _haltTimer?.cancel();
    _endingTrip.close();
    _startingReturn.close();
    _haltTick.close();
    _extent.close();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowCoachMarks() async {
    if (!mounted || CoachMarks.isVisible) return;
    if (!await LocalStorageService.isSignupUser()) return;
    if (await LocalStorageService.hasSeenCoachMark(_coachKey)) return;
    if (!mounted) return;

    final steps = <CoachMark>[
      if (_etaCoachKey.currentContext != null)
        CoachMark(
          targetKey: _etaCoachKey,
          title: 'Arriving in',
          description: 'Live estimate of how long until you reach the destination.',
        ),
      if (_distanceCoachKey.currentContext != null)
        CoachMark(
          targetKey: _distanceCoachKey,
          title: 'Distance left',
          description: 'Kilometres still to go on this leg. Updates as the driver moves.',
        ),
      if (_otpCoachKey.currentContext != null)
        CoachMark(
          targetKey: _otpCoachKey,
          title: 'End trip OTP',
          description: 'Share this code with the driver only when you reach the destination. Tap to copy it.',
        ),
      if (_shareCoachKey.currentContext != null)
        CoachMark(
          targetKey: _shareCoachKey,
          title: 'Share your ride',
          description: 'Send a live tracking link to family so they can follow the trip.',
        ),
      if (_endTripCoachKey.currentContext != null)
        CoachMark(
          targetKey: _endTripCoachKey,
          title: 'Request end trip',
          description: 'Ask the driver to close the trip once you have reached your drop point.',
        ),
      if (_returnTripCoachKey.currentContext != null)
        CoachMark(
          targetKey: _returnTripCoachKey,
          title: 'Start return trip',
          description: 'Round trip only. Tap when you are ready to head back to the pickup point.',
        ),
      if (_detailsCoachKey.currentContext != null)
        CoachMark(
          targetKey: _detailsCoachKey,
          title: 'Full trip details',
          description: 'Route, stops, fare breakdown and timeline for this booking.',
        ),
    ];

    if (steps.isEmpty) return;
    CoachMarks.show(context, steps: steps, onFinish: () => LocalStorageService.setSeenCoachMark(_coachKey));
  }

  void _syncHaltTimer(bool halted) {
    if (halted && _haltTimer == null) {
      _haltTimer = Timer.periodic(const Duration(seconds: 30), (_) => _haltTick.value++);
    } else if (!halted && _haltTimer != null) {
      _haltTimer?.cancel();
      _haltTimer = null;
    }
  }

  void _syncExtent() {
    if (!mounted || _screenHeight <= 0) return;
    final double contentHeight = _contentKey.currentContext?.size?.height ?? 0;
    if (contentHeight <= 0) return;
    final double target = ((contentHeight + _extraSheetSpace) / _screenHeight).clamp(_minSheetExtent, _maxSheetExtent);
    if ((target - _extent.value).abs() < 0.005) return;
    _extent.value = target;
    widget.onExtent?.call(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(target, duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic);
      }
    });
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Card(
      elevation: 3,
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
        ),
        child: child,
      ),
    );
  }

  Widget _iconTile(IconData icon, Color fg, Color bg, {double size = 36, double radius = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: size * 0.5, color: fg),
    );
  }

  Widget _stat({
    required IconData icon,
    required Color tint,
    required Color tintBg,
    required String label,
    required String value,
    required String unit,
    required String note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 10.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: tintBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: tint),
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: label, fontSize: 11, color: AppColors.grey500, textAlign: TextAlign.left),
                2.height,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Poppins', color: AppColors.grey900),
                      children: [
                        TextSpan(
                          text: value,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (unit.isNotEmpty)
                          TextSpan(
                            text: ' $unit',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.grey300,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Icon(icon, size: 18, color: AppColors.charcoal),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required bool busy,
    required VoidCallback onTap,
  }) {
    const radius = BorderRadius.all(Radius.circular(14));
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: busy ? null : onTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 17, color: AppColors.white),
                          7.width,
                          Flexible(
                            child: CustomText(
                              text: label,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripStateService = Get.find<TripStateService>();

    _screenHeight = MediaQuery.sizeOf(context).height;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());

    return Obx(
      () => DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _extent.value,
        minChildSize: _minSheetExtent,
        maxChildSize: _extent.value,
        builder: (context, scrollController) {
          return Obx(() {
            final activeTrip = tripStateService.selectedTrip;
            final bool hasSheetImg = (driverData['image']?.toString().trim().isNotEmpty ?? false);
            if (!hasSheetImg &&
                (activeTrip?.driverImage ?? '').trim().isEmpty &&
                (activeTrip?.bookingId ?? '').isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => tripStateService.ensureDriverImage(activeTrip!.bookingId!),
              );
            }

            final TripDistanceController? tripDistance = Get.isRegistered<TripDistanceController>()
                ? Get.find<TripDistanceController>()
                : null;

            final double? roadKm = tripDistance?.distanceKm.value;
            final int? etaMins = tripDistance?.etaMinutes.value;

            final bool hasDistance = roadKm != null && roadKm > 0 && double.parse(roadKm.toStringAsFixed(1)) > 0;
            final bool hasEta = etaMins != null && etaMins > 0;
            final String displayDistance = hasDistance ? roadKm.toStringAsFixed(1) : '';
            final String displayArrival = hasEta ? _formatEta(etaMins) : '';
            final String arrivalNote = hasEta ? 'at ${_clockAfter(etaMins)}' : '';

            final String displayRating = activeTrip?.driverRating?.toStringAsFixed(1) ?? '0';
            final String vehicleType = activeTrip?.vehicleType ?? '';
            final bool hasRating =
                displayRating != '0' && displayRating != 'null' && displayRating != 'NaN' && displayRating != '0.0';
            final String displayName = activeTrip?.driverName ?? 'No name';
            final String displayPlate = activeTrip?.plateNumber ?? '0';
            final String pickupLocation = activeTrip?.pickupLocation ?? 'unknown';
            final bool isRoundTrip = tripStateService.isSelectedRoundTrip;
            final int leg = tripStateService.selectedLeg;
            final bool isHalted = tripStateService.isSelectedHalted;
            _syncHaltTimer(isHalted);
            final String displayDest =
                tripStateService.activeDestinationLabelFor(null) ?? activeTrip?.destinationLocation ?? 'unknown';

            final String phaseTitle = isHalted
                ? 'Waiting at destination'
                : leg >= 2
                ? 'Returning to pickup'
                : 'Going to destination';
            final String distanceNote = leg >= 2 ? 'to pickup' : 'to destination';

            _extraSheetSpace = _baseSheetSpace + MediaQuery.paddingOf(context).bottom;
            WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  key: _contentKey,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    10.height,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isRoundTrip) ...[
                            Row(
                              children: [
                                _iconTile(Icons.sync, AppColors.orange, AppColors.orange50, radius: 18),
                                10.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const CustomText(
                                        text: 'Round Trip',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.orange,
                                        textAlign: TextAlign.left,
                                      ),
                                      CustomText(
                                        text: phaseTitle,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.grey900,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // CustomText(
                                      //   text: '$leg of 2',
                                      //   fontSize: 11,
                                      //   color: AppColors.grey500,
                                      //   textAlign: TextAlign.left,
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            12.height,
                          ],

                          if (hasEta || hasDistance) ...[
                            Row(
                              children: [
                                if (hasEta)
                                  Expanded(
                                    key: _etaCoachKey,
                                    child: _stat(
                                      icon: Icons.access_time,
                                      tint: AppColors.successGreen,
                                      tintBg: AppColors.successGreenLight,
                                      label: 'Arriving in',
                                      value: displayArrival,
                                      unit: '',
                                      note: arrivalNote,
                                    ),
                                  ),
                                if (hasEta && hasDistance)
                                  Container(
                                    width: 1,
                                    height: 46,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    color: AppColors.grey100,
                                  ),
                                if (hasDistance)
                                  Expanded(
                                    key: _distanceCoachKey,
                                    child: _stat(
                                      icon: Icons.place_outlined,
                                      tint: AppColors.orange,
                                      tintBg: AppColors.orange50,
                                      label: 'Distance left',
                                      value: displayDistance,
                                      unit: 'km',
                                      note: distanceNote,
                                    ),
                                  ),
                              ],
                            ),
                            10.height,
                          ],
                          10.height,
                          _card(
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    AvatarImage(
                                      size: 48,
                                      url: hasSheetImg ? driverData['image'].toString() : activeTrip?.driverImage,
                                    ),
                                  ],
                                ),
                                10.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CustomText(
                                            text: displayName,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            textAlign: TextAlign.left,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (hasRating) ...[
                                            10.width,
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF7E6),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFFFFD77A)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                                                  const SizedBox(width: 4),
                                                  CustomText(
                                                    text: displayRating,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF8A5A00),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      4.height,

                                      Row(
                                        children: [
                                          CustomText(text: vehicleType, fontSize: 11, color: AppColors.grey500),

                                          6.width,

                                          CustomText(text: '●', fontSize: 12, color: AppColors.grey400),

                                          6.width,

                                          Flexible(
                                            child: CustomText(
                                              text: displayPlate,
                                              fontSize: 11,
                                              color: AppColors.grey500,
                                              textAlign: TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                8.width,
                                _contactButton(
                                  icon: Icons.forum_outlined,
                                  label: 'Message',
                                  onTap:
                                      widget.onMessage ??
                                      () => Get.toNamed(AppRoutes.chat, arguments: {'type': 'support'}),
                                ),
                              ],
                            ),
                          ),

                          if (!isHalted) ...[
                            10.height,
                            _card(
                              child: Row(
                                children: [
                                  Row(
                                    key: _otpCoachKey,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _iconTile(Icons.shield_outlined, AppColors.amber600, AppColors.amber50),
                                      10.width,
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const CustomText(
                                            text: 'End trip OTP',
                                            fontSize: 11,
                                            color: AppColors.grey500,
                                            textAlign: TextAlign.left,
                                          ),
                                          CustomText(
                                            text: _otpDigits(activeTrip?.endOtp),
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.orange,
                                            letterSpacing: 2,
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () async {
                                      final id = activeTrip?.bookingId ?? '';
                                      if (id.isEmpty) return;
                                      await TripShareService.share(
                                        bookingId: id,
                                        pickup: activeTrip?.pickupLocation ?? pickupLocation,
                                        dropoff: activeTrip?.destinationLocation ?? displayDest,
                                      );
                                    },
                                    child: Container(
                                      key: _shareCoachKey,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.orange),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.share_outlined, size: 14, color: AppColors.orange),
                                          5.width,
                                          const CustomText(
                                            text: 'Share trip',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.orange,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          10.height,
                          Row(
                            children: [
                              Expanded(
                                key: _endTripCoachKey,
                                child: Obx(
                                  () => _actionButton(
                                    icon: Icons.outlined_flag,
                                    color: AppColors.grey400,
                                    label: 'Request End Trip',
                                    busy: _endingTrip.value,
                                    onTap: () => _requestEndTrip(tripStateService),
                                  ),
                                ),
                              ),
                              if (isRoundTrip && tripStateService.selectedLeg < 2) ...[
                                10.width,
                                Expanded(
                                  key: _returnTripCoachKey,
                                  child: Obx(
                                    () => _actionButton(
                                      icon: Icons.u_turn_left,
                                      color: AppColors.orange,
                                      label: 'Start Return',
                                      busy: _startingReturn.value,
                                      onTap: () => _startReturnJourney(tripStateService),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          10.height,
                          GestureDetector(
                            onTap: widget.onTripDetails ?? () => Get.toNamed(AppRoutes.tripDetails),
                            child: Container(
                              key: _detailsCoachKey,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientButton,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orange.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _iconTile(
                                    Icons.description_outlined,
                                    AppColors.white,
                                    AppColors.white.withValues(alpha: 0.2),
                                    size: 32,
                                  ),
                                  10.width,
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          text: 'Trip Details',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                          textAlign: TextAlign.left,
                                        ),
                                        CustomText(
                                          text: 'Route, fare and timeline',
                                          fontSize: 10,
                                          color: AppColors.white,
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          MediaQuery.paddingOf(context).bottom.height,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  String _formatEta(int minutes) {
    if (minutes >= 60) {
      final int h = minutes ~/ 60;
      final int m = minutes % 60;
      return '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  String _clockAfter(int minutes) {
    final DateTime at = DateTime.now().add(Duration(minutes: minutes));
    final int hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final String minute = at.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  String _otpDigits(String? otp) {
    final v = (otp != null && otp.isNotEmpty && otp != '0' && otp != '----') ? otp : '----';
    return v.split('').join(' ');
  }

  Future<bool> _confirm({
    required IconData icon,
    required Color accent,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 28),
              ),
              16.height,
              CustomText(text: title, fontSize: 16, fontWeight: FontWeight.bold),
              8.height,
              CustomText(text: message, fontSize: 13, color: AppColors.grey600, textAlign: TextAlign.center),
              20.height,
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
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
                        height: 46,
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: CustomText(
                            text: confirmLabel,
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
            ],
          ),
        ),
      ),
    );
    return confirmed == true;
  }

  Future<void> _requestEndTrip(TripStateService tripState) async {
    if (_endingTrip.value) return;
    final trip = tripState.selectedTrip;
    final String tripId = trip?.bookingId ?? '';
    final String bookingId = tripId.isNotEmpty ? tripId : tripState.selectedBookingId.value;
    if (bookingId.isEmpty) return;

    final bool confirmed = await _confirm(
      icon: Icons.outlined_flag,
      accent: AppColors.red,
      title: 'Request End Trip?',
      message: 'This will ask your driver to end the trip now. Do you want to continue?',
      confirmLabel: 'End Trip',
    );
    if (!confirmed) return;

    _endingTrip.value = true;
    try {
      final message = await TripsRepository().requestEndTrip(bookingId);
      AppSnackbar.success('End Trip Requested', message);
    } on ApiException catch (e) {
      AppSnackbar.error('End Trip Failed', e.message);
    } finally {
      _endingTrip.value = false;
    }
  }

  Future<void> _startReturnJourney(TripStateService tripState) async {
    if (_startingReturn.value) return;
    final trip = tripState.selectedTrip;
    final String tripId = trip?.bookingId ?? '';
    final String bookingId = tripId.isNotEmpty ? tripId : tripState.selectedBookingId.value;
    if (bookingId.isEmpty) return;

    final bool confirmed = await _confirm(
      icon: Icons.sync,
      accent: AppColors.orange,
      title: 'Start Return Trip?',
      message: 'Your driver will be asked to begin the return journey to your pickup point.',
      confirmLabel: 'Start Return',
    );
    if (!confirmed) return;

    _startingReturn.value = true;
    try {
      final result = await TripsRepository().startReturnTrip(bookingId);
      tripState.advanceToReturnLeg(bookingId, endOtp: result.endOtp);
      AppSnackbar.success('Return Journey Started', result.message);
    } on ApiException catch (e) {
      AppSnackbar.error('Return Journey Failed', e.message);
    } finally {
      _startingReturn.value = false;
    }
  }
}
