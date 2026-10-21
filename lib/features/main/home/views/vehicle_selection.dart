import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/payment_controller.dart';
import 'package:orange_taxi_customer_app/features/main/payment/widgets/payment_selection_sheet.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';

class VehicleSelectionBottomSheet extends GetView<VehicleSelectionController> {
  VehicleSelectionBottomSheet({super.key});

  final int finalPrice = 0;
  final PaymentController paymentController = Get.put(PaymentController());
  final TripController tripController = Get.put(TripController());
  final HomeController homeController = Get.put(HomeController());

  static const String _coachKey = 'vehicle_selection_coach';
  final GlobalKey _coachVehicleKey = GlobalKey();
  final GlobalKey _coachPaymentKey = GlobalKey();
  final GlobalKey _coachScheduleKey = GlobalKey();
  final RxBool _coachChecked = false.obs;

  void _maybeShowCoachMarks(BuildContext context) {
    if (_coachChecked.value) return;
    _coachChecked.value = true;
    Future(() async {
      if (!await LocalStorageService.isSignupUser()) return;
      if (await LocalStorageService.hasSeenCoachMark(_coachKey)) return;
      await Future.delayed(const Duration(milliseconds: 700));
      if (!context.mounted) return;
      CoachMarks.show(context, steps: _coachSteps(), onFinish: () => LocalStorageService.setSeenCoachMark(_coachKey));
    });
  }

  List<CoachMark> _coachSteps() {
    return [
      CoachMark(
        targetKey: _coachVehicleKey,
        title: 'Choose a vehicle',
        description: 'Tap a vehicle to select it. Each option shows its own fare, seats and per-km rate.',
        holeRadius: 22,
      ),
      CoachMark(
        targetKey: _coachPaymentKey,
        title: 'Payment & offers',
        description: 'Switch between wallet, cash or online, book on someone else\'s behalf, and apply an offer code.',
        holeRadius: 16,
      ),
      if (tripController.selectedType.value != TripType.roundTrip)
        CoachMark(
          targetKey: _coachScheduleKey,
          title: 'Ride now or later',
          description: 'Book instantly, or schedule the pickup for a later date and time.',
          holeRadius: 14,
          holePadding: 10,
        ),
    ];
  }

  void showScheduleBottomSheet(BuildContext context, {bool isDrop = false, bool scheduleFirst = false}) async {
    final now = DateTime.now();
    final RxBool draftScheduled = (controller.isScheduled.value || scheduleFirst).obs;
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final List<String> dates = [];
    for (int i = 0; i <= 30; i++) {
      final date = now.add(Duration(days: i));
      if (i == 0) {
        dates.add('Today');
      } else if (i == 1) {
        dates.add('Tomorrow');
      } else {
        dates.add(
          '${weekdays[date.weekday - 1]} '
          '${date.day} '
          '${months[date.month - 1]}',
        );
      }
    }
    final int minHours = controller.minScheduleHours.value;
    final DateTime minDateTime = now.add(Duration(hours: minHours));
    final int minDayOffset = DateUtils.dateOnly(minDateTime).difference(DateUtils.dateOnly(now)).inDays;
    final int minHour12 = minDateTime.hour % 12 == 0 ? 12 : minDateTime.hour % 12;

    final FixedExtentScrollController dateController = FixedExtentScrollController(initialItem: minDayOffset);
    final FixedExtentScrollController hourController = FixedExtentScrollController(initialItem: minHour12 - 1);
    final FixedExtentScrollController minuteController = FixedExtentScrollController(initialItem: minDateTime.minute);
    final FixedExtentScrollController amPmController = FixedExtentScrollController(
      initialItem: minDateTime.hour >= 12 ? 1 : 0,
    );

    controller.selectedDate.value = minDateTime;
    controller.selectedHour.value = minHour12;
    controller.selectedMinute.value = minDateTime.minute;
    controller.isAM.value = minDateTime.hour < 12;

    DateTime composeSelected() {
      final h24 = controller.isAM.value
          ? (controller.selectedHour.value == 12 ? 0 : controller.selectedHour.value)
          : (controller.selectedHour.value == 12 ? 12 : controller.selectedHour.value + 12);
      return DateTime(
        controller.selectedDate.value.year,
        controller.selectedDate.value.month,
        controller.selectedDate.value.day,
        h24,
        controller.selectedMinute.value,
      );
    }

    void enforceMinDateTime() {
      if (!composeSelected().isBefore(minDateTime)) return;
      const dur = Duration(milliseconds: 250);
      const curve = Curves.easeOut;
      dateController.animateToItem(minDayOffset, duration: dur, curve: curve);
      hourController.animateToItem(minHour12 - 1, duration: dur, curve: curve);
      minuteController.animateToItem(minDateTime.minute, duration: dur, curve: curve);
      amPmController.animateToItem(minDateTime.hour >= 12 ? 1 : 0, duration: dur, curve: curve);
      controller.selectedDate.value = minDateTime;
      controller.selectedHour.value = minHour12;
      controller.selectedMinute.value = minDateTime.minute;
      controller.isAM.value = minDateTime.hour < 12;
    }

    await Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),

        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,

                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
              ),
            ),

            20.height,

            if (!isDrop && !scheduleFirst)
              Obx(
                () => CupertinoSlidingSegmentedControl<bool>(
                  groupValue: draftScheduled.value,
                  backgroundColor: AppColors.grey200,
                  thumbColor: AppColors.white,
                  children: {
                    false: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: CustomText(
                        text: 'Ride Now',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    true: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: CustomText(
                        text: 'Schedule Ride',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value == null) return;
                    draftScheduled.value = value;
                  },
                ),
              ),
            10.height,

            Obx(() {
              final bool isRideNow = !draftScheduled.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  CustomText(
                    text: isDrop
                        ? 'Schedule Return Ride'
                        : isRideNow
                        ? 'Book Ride Now'
                        : 'Schedule Your Ride',

                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),

                  8.height,

                  CustomText(
                    text: isDrop
                        ? 'Choose your preferred return time.'
                        : isRideNow
                        ? 'Get connected instantly with nearby drivers for faster pickup.'
                        : 'Schedule your ride at least ${controller.minScheduleHours.value} hour${controller.minScheduleHours.value == 1 ? '' : 's'} in advance.',

                    fontSize: 14,
                    color: AppColors.grey,
                    textAlign: TextAlign.left,
                  ),
                ],
              );
            }),

            30.height,

            Obx(() {
              final isScheduled = draftScheduled.value;
              if (!isDrop && !isScheduled) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(20)),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),

                        child: Icon(Icons.local_taxi, color: AppColors.primary, size: 26),
                      ),

                      14.width,

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            CustomText(
                              text: 'Ride Now',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),

                            4.height,

                            const CustomText(
                              text: 'Your booking is typically confirmed within 5–10 minutes.',
                              fontSize: 13,
                              textAlign: TextAlign.left,
                              color: AppColors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,

                        child: Center(
                          child: CustomText(
                            text: 'Date',

                            color: AppColors.grey,

                            fontSize: 14,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: CustomText(
                            text: 'Time',

                            color: AppColors.grey,

                            fontSize: 14,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Expanded(child: SizedBox.shrink()),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),

                  10.height,

                  SizedBox(
                    height: 200,

                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            scrollController: dateController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              controller.selectedDate.value = now.add(Duration(days: index));
                              enforceMinDateTime();
                            },

                            children: dates
                                .map(
                                  (d) => Center(
                                    child: CustomText(text: d, fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        Expanded(
                          child: CupertinoPicker(
                            scrollController: hourController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              controller.selectedHour.value = index + 1;
                              enforceMinDateTime();
                            },

                            children: List.generate(
                              12,
                              (index) => Center(
                                child: CustomText(text: '${index + 1}', fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: CupertinoPicker(
                            scrollController: minuteController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              controller.selectedMinute.value = index;
                              enforceMinDateTime();
                            },

                            children: List.generate(
                              60,
                              (index) => Center(
                                child: CustomText(
                                  text: index.toString().padLeft(2, '0'),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: CupertinoPicker(
                            scrollController: amPmController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              controller.isAM.value = index == 0;
                              enforceMinDateTime();
                            },

                            children: [
                              Center(
                                child: CustomText(text: 'AM', fontSize: 16, fontWeight: FontWeight.bold),
                              ),

                              Center(
                                child: CustomText(text: 'PM', fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),

            30.height,

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: !isDrop ? 'Continue' : 'Confirm Drop',

                    onPressed: () async {
                      if (!isDrop && !draftScheduled.value) {
                        controller.isScheduled.value = false;
                        controller.scheduledPickupTime.value = 'Now';
                        controller.pickupDate.value = DateTime.now().toIso8601String();
                        Get.back();
                        await Future.delayed(const Duration(milliseconds: 300));
                        controller.refreshEstimationForSchedule();
                        return;
                      }

                      DateTime scheduledDateTime = DateTime(
                        controller.selectedDate.value.year,
                        controller.selectedDate.value.month,
                        controller.selectedDate.value.day,

                        controller.isAM.value
                            ? (controller.selectedHour.value == 12 ? 0 : controller.selectedHour.value)
                            : (controller.selectedHour.value == 12 ? 12 : controller.selectedHour.value + 12),

                        controller.selectedMinute.value,
                      );

                      final int minHours = controller.minScheduleHours.value;
                      if (scheduledDateTime.isBefore(DateTime.now().add(Duration(hours: minHours)))) {
                        AppSnackbar.warning(
                          'Invalid Date or Time',
                          "Schedule your ride at least $minHours hour${minHours == 1 ? '' : 's'} in advance.",
                        );
                      } else {
                        if (!isDrop) {
                          controller.isScheduled.value = true;
                        }

                        if (isDrop) {
                          controller.scheduledDropTime.value = DateFormat('d MMM, hh:mm a').format(scheduledDateTime);
                          controller.dropDate.value = scheduledDateTime.toIso8601String();
                        } else {
                          controller.scheduledPickupTime.value = DateFormat('d MMM, hh:mm a').format(scheduledDateTime);
                          controller.pickupDate.value = scheduledDateTime.toIso8601String();
                        }

                        Get.back();
                        await Future.delayed(const Duration(milliseconds: 300));
                        controller.refreshEstimationForSchedule();
                      }
                    },

                    gradient: AppColors.gradientButton,
                    textColor: AppColors.white,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
            20.height,
          ],
        ),
      ),

      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowCoachMarks(context);
    return SafeArea(child: _buildSheetBody(context));
  }

  Widget _buildSheetBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          20.height,

          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
            ),
          ),

          Obx(() {
            final String? code = controller.appliedOfferId.value;
            if (code == null || code.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.green),
                  8.width,
                  CustomText(
                    text: '"$code" Applied',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ],
              ),
            );
          }),

          20.height,

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                text: 'SELECT VEHICLE',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.grey650,
              ),
            ),
          ),

          15.height,
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 160, maxHeight: (Get.height * 0.42).clamp(240.0, 460.0)),

            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildVehicleSkeletonList();
              }

              if (controller.vehicles.isEmpty) {
                return const Center(
                  child: CustomText(text: 'No vehicles available for this route.', color: AppColors.grey),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  // vertical: 10,
                ),

                physics: const BouncingScrollPhysics(),
                itemCount: controller.vehicles.length,
                // separatorBuilder: (_, _) => 14.height,
                itemBuilder: (context, index) {
                  final vehicle = controller.vehicles[index];

                  final Widget tile = Obx(() {
                    final isSelected = controller.selectedVehicleIndex.value == index;
                    final bool rideLater = controller.isRideLaterOnly(vehicle);
                    final Color accent = rideLater ? AppColors.warning : AppColors.orange;
                    return GestureDetector(
                      onTap: () => controller.selectedVehicleIndex.value = index,

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? accent.withValues(alpha: 0.08) : AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: isSelected ? accent : AppColors.transparent, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 65,
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),

                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.network(
                                  vehicle['vehicle_image_url'] ?? "",
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset('assets/images/car.png', fit: BoxFit.contain);
                                  },
                                ),
                              ),
                            ),

                            14.width,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Row(
                                    children: [
                                      CustomText(
                                        text: vehicle['name'] ?? vehicle['vehicle_type'] ?? '',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      4.width,
                                      Icon(Icons.airline_seat_recline_normal_rounded, size: 18, color: AppColors.grey),
                                      Transform.translate(
                                        offset: const Offset(-3, -8),
                                        child: CustomText(
                                          text: vehicle['seats'].toString(),
                                          fontSize: 11,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (rideLater) ...[
                                    6.height,
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.event_available_rounded, size: 12, color: AppColors.warning),
                                          5.width,
                                          const CustomText(
                                            text: 'Not available now',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.warning,
                                          ),
                                        ],
                                      ),
                                    ),
                                    4.height,
                                    const CustomText(
                                      text: 'Schedule this ride for later',
                                      fontSize: 11,
                                      color: AppColors.grey,
                                      textAlign: TextAlign.left,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],

                                  if (!rideLater)
                                    Obx(() {
                                      if (controller.isPriceLoading.value) return const SizedBox.shrink();
                                      final num d = num.tryParse('${vehicle['discount_amount'] ?? 0}') ?? 0;
                                      final String offer = (vehicle['offer_title'] ?? '').toString();
                                      if (d <= 0 || offer.isEmpty) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4, bottom: 2),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.local_offer, size: 11, color: AppColors.orange),
                                              4.width,
                                              CustomText(
                                                text: offer,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.orange,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),

                                  if (!rideLater)
                                    Obx(
                                      () => controller.isPriceLoading.value
                                          ? Shimmer(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SkeletonBox(width: 90, height: 12),
                                                  4.height,
                                                  SkeletonBox(width: 90, height: 12),
                                                ],
                                              ),
                                            )
                                          : Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              children: [
                                                CustomText(
                                                  text:
                                                      "Driver Beta ${AppConstants.rupeesSymbol}${vehicle['driver_beta']}",
                                                  fontSize: 12,
                                                  color: AppColors.grey,
                                                ),
                                                Icon(Icons.circle, size: 6, color: AppColors.grey600),
                                                CustomText(
                                                  text:
                                                      'Price per km ${AppConstants.rupeesSymbol}${vehicle['price_per_km'] ?? 0}',
                                                  fontSize: 12,
                                                  color: AppColors.grey,
                                                ),
                                              ],
                                            ),
                                    ),

                                  8.height,
                                ],
                              ),
                            ),

                            10.width,

                            Obx(() {
                              if (controller.isPriceLoading.value) {
                                return const Shimmer(child: SkeletonBox(width: 56, height: 20));
                              }
                              final num total = num.tryParse('${vehicle['total_fare'] ?? 0}') ?? 0;
                              final num discount = num.tryParse('${vehicle['discount_amount'] ?? 0}') ?? 0;
                              final num finalAfter =
                                  num.tryParse('${vehicle['final_fare_after_discount'] ?? total}') ?? total;

                              if (discount <= 0) {
                                return CustomText(text: "₹$total", fontSize: 18, fontWeight: FontWeight.bold);
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    text: "₹$total",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.grey,
                                    textDecoration: TextDecoration.lineThrough,
                                  ),
                                  CustomText(text: "₹$finalAfter", fontSize: 18, fontWeight: FontWeight.bold),
                                  3.height,
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.savings_outlined, size: 11, color: AppColors.green),
                                        3.width,
                                        CustomText(
                                          text: "SAVE ₹$discount",
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.green,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  });

                  return index == 0 ? KeyedSubtree(key: _coachVehicleKey, child: tile) : tile;
                },
              );
            }),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Obx(() {
              final bool hideSchedule =
                  tripController.selectedType.value == TripType.roundTrip || controller.selectedNeedsRideLater;

              return Row(
                children: [
                  Expanded(
                    key: _coachPaymentKey,
                    child: Obx(() {
                      final bool forOthers = paymentController.selectedBookingFor.value == 'others';
                      final String othersPhone = paymentController.isPhoneConfirmed.value
                          ? paymentController.phoneNumberController.text.trim()
                          : '';

                      return _buildFooterOption(
                        icon: Icons.payments,
                        title: forOthers && othersPhone.isNotEmpty ? othersPhone : 'Personal',
                        subtitle: paymentController.selectedPaymentMethod.value == 'upi'
                            ? 'Online'
                            : paymentController.selectedPaymentMethod.value.capitalize!,
                        isPayment: true,
                        context: context,
                      );
                    }),
                  ),

                  if (!hideSchedule) ...[
                    ValueListenableBuilder<bool>(
                      valueListenable: CoachMarks.isShowing,
                      builder: (context, showing, child) =>
                          Container(width: 1, height: 40, color: showing ? AppColors.transparent : AppColors.grey300),
                    ),
                    Expanded(
                      key: _coachScheduleKey,
                      child: _buildFooterOption(
                        icon: Icons.calendar_month,
                        title: controller.isScheduled.value ? 'Later' : 'Now',
                        subtitle: controller.isScheduled.value ? controller.scheduledPickupTime.value : '',
                        isPayment: false,
                        context: context,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
          if (tripController.selectedType.value == TripType.roundTrip) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),

              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _buildFooterOption(
                        icon: Icons.calendar_month,
                        title: 'Pickup Date',
                        subtitle: controller.scheduledPickupTime.value.isEmpty
                            ? 'Now'
                            : controller.scheduledPickupTime.value,
                        isPayment: false,
                        context: context,
                        isDrop: false,
                      ),
                    ),
                  ),

                  Container(width: 1, height: 40, color: AppColors.grey300),

                  Expanded(
                    child: Obx(
                      () => _buildFooterOption(
                        icon: Icons.calendar_month,
                        title: 'Drop Date',
                        subtitle: controller.scheduledDropTime.value.isEmpty
                            ? 'Select Date'
                            : controller.scheduledDropTime.value,
                        isPayment: false,
                        context: context,
                        isDrop: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

              child: CustomButton(
                text: controller.selectedNeedsRideLater ? 'Ride Later' : 'Review Booking',
                onPressed: controller.selectedVehicleIndex.value == -1 || controller.isLoading.value
                    ? () {}
                    : controller.selectedNeedsRideLater
                    ? () => showScheduleBottomSheet(context, scheduleFirst: true)
                    : () async {
                        final success = await controller.createBooking(
                          pickup: homeController.pickupAddress.value,
                          drop: homeController.destinationAddress.value,
                          distance: homeController.distance.value,
                          duration: homeController.duration.value,
                          serviceTypeId: tripController.serviceId,
                          stops: homeController.formattedStops,
                          pickupDateTime: DateTime.tryParse(controller.pickupDate.value) ?? DateTime.now(),
                          dropDateTime: DateTime.tryParse(controller.dropDate.value),
                        );
                        if (success) {
                          final homeController = Get.find<HomeController>();
                          final selectedVehicle = controller.vehicles[controller.selectedVehicleIndex.value];
                          Get.toNamed(
                            AppRoutes.tripSummary,
                            arguments: {
                              'isScheduled': controller.isScheduled.value,
                              'pickup': homeController.pickupAddress.value,
                              'dropoff': homeController.destinationAddress.value,
                              'price': selectedVehicle['total_fare'].toString(),
                              'vehicleType': (selectedVehicle['name'] ?? selectedVehicle['vehicle_type'] ?? '')
                                  .toString(),
                            },
                          );
                        }
                      },
                gradient: controller.selectedVehicleIndex.value == -1
                    ? AppColors.disabledGradient
                    : AppColors.gradientButton,
                textColor: AppColors.white,
                icon: controller.selectedNeedsRideLater ? Icons.event_available_rounded : Icons.arrow_forward,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSkeletonList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer(
        key: index == 0 ? _coachVehicleKey : null,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            children: [
              SkeletonBox(width: 80, height: 65, radius: 16),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonBox(width: 110, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 6),
                    SkeletonBox(width: 130, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 10),
              SkeletonBox(width: 56, height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPayment,
    required BuildContext context,
    bool isDrop = false,
  }) {
    return InkWell(
      onTap: () {
        if (!isPayment) {
          showScheduleBottomSheet(context, isDrop: isDrop);
        } else {
          PaymentBottomSheet.show(context);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,

        children: [
          10.width,
          if (!isPayment) Icon(icon, color: AppColors.primary, size: 20),
          if (!isPayment) 5.width,

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,

            children: [
              CustomText(text: title, fontSize: 14, fontWeight: FontWeight.bold),

              Row(
                children: [
                  if (isPayment) Icon(icon, color: AppColors.primary, size: 20),
                  if (isPayment) 5.width,

                  if (isPayment || subtitle.isNotEmpty) CustomText(text: subtitle, fontSize: 12, color: AppColors.grey),
                ],
              ),
            ],
          ),

          Spacer(),

          Container(
            decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(50)),
            child: Icon(Icons.chevron_right, color: AppColors.black, size: 20),
          ),
          15.width,
        ],
      ),
    );
  }
}
