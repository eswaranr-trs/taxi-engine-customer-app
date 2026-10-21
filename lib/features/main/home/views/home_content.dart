import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/widgets/airport_selection_bottom_sheet.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import '../controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/features/main/notifications/controllers/notifications_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/features/main/home/widgets/stops_reorder_sheet.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final controller = Get.find<HomeController>();
  final tripController = Get.find<TripController>();

  final GlobalKey coachTripTypeKey = GlobalKey();
  final GlobalKey coachRouteKey = GlobalKey();
  final GlobalKey coachAddStopKey = GlobalKey();
  final GlobalKey coachNotificationsKey = GlobalKey();

  Worker? _coachWorker;

  @override
  void initState() {
    super.initState();
    _coachWorker = ever(controller.showCoachMarks, (bool show) {
      if (show) _showCoachMarks();
    });
    if (controller.showCoachMarks.value) _showCoachMarks();
  }

  @override
  void dispose() {
    _coachWorker?.dispose();
    if (CoachMarks.isVisible) CoachMarks.dismiss();
    super.dispose();
  }

  void _showCoachMarks() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || CoachMarks.isVisible) return;
      if (!controller.showCoachMarks.value || controller.isMapSelectionMode.value) return;
      CoachMarks.show(context, steps: _coachSteps(), onFinish: controller.finishHomeCoachMarks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMap(),

        Obx(() => controller.isMapSelectionMode.value ? _buildCenterPin() : const SizedBox.shrink()),
        Obx(
          () => controller.isMapSelectionMode.value
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => controller.isMapSelectionMode.value = false,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 10, offset: Offset(0, 5))],
                          ),
                          child: const Icon(Icons.close, color: AppColors.black),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        SafeArea(
          child: Obx(
            () => AnimatedOpacity(
              opacity: controller.isMapSelectionMode.value ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: controller.isMapSelectionMode.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    14.height,
                    _buildTripTypeSelector(),
                    20.height,
                    tripController.selectedType.value == TripType.airportTransfer
                        ? _buildAirportTransferCard()
                        : _buildLocationCard(),
                    10.height,
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: KeyedSubtree(key: coachNotificationsKey, child: _buildNotificationButton()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<CoachMark> _coachSteps() => [
    CoachMark(
      targetKey: coachTripTypeKey,
      title: 'Service type',
      description: 'Pick how you want to ride. One Way drops you at your destination — no return trip.',
      holeRadius: 15,
      holePadding: 4,
    ),
    CoachMark(
      targetKey: coachRouteKey,
      title: 'Your route',
      description:
          'Pickup is set to where you are now — tap it to search another point. Tap Destination for your drop.',
      holeRadius: 28,
      holePadding: 4,
    ),
    CoachMark(
      targetKey: coachAddStopKey,
      title: 'Add a stop',
      description: 'Tap + to add up to 3 stops along the way. Added stops show below your destination.',
      holeRadius: 16,
      holePadding: 6,
    ),
    CoachMark(
      targetKey: coachNotificationsKey,
      title: 'Notifications',
      description: 'Trip updates and alerts land here. The badge shows how many are unread.',
      holeRadius: 20,
      holePadding: 6,
    ),
  ];

  Widget _buildMap() {
    return Obx(
      () => GoogleMap(
        initialCameraPosition: CameraPosition(target: controller.currentLocation.value, zoom: 13),
        onMapCreated: (c) {
          controller.onHomeMapCreated(c);
          // controller.setMapStyle();
        },
        onCameraMove: (position) {
          if (controller.isMapSelectionMode.value) {
            controller.onCameraMove(position);
          }
        },

        onCameraIdle: () {
          if (controller.isMapSelectionMode.value) {
            controller.onCameraIdle();
          }
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        polylines: const {},
        padding: EdgeInsets.only(top: 200),
        markers: controller.isMapSelectionMode.value ? {} : controller.driverMarkers.toSet(),
      ),
    );
  }

  Widget _buildCenterPin() {
    return Obx(() {
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.black87, borderRadius: BorderRadius.circular(20)),
                child: CustomText(
                  text: controller.editingSavedAddressType != null
                      ? 'Tap pin to set ${controller.editingSavedAddressType}'
                      : 'Tap pin to set location',
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
              8.height,
              GestureDetector(
                onTap: () => controller.confirmMapLocation(),
                child: Icon(
                  Icons.location_on,
                  size: 55,
                  color: controller.isSelectingPickup.value ? AppColors.primary : AppColors.redAccent,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNotificationButton() {
    final notifCtrl = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());
    return GestureDetector(
      onTap: () async {
        await Get.toNamed(AppRoutes.notifications);
        notifCtrl.fetchUnreadCount();
      },
      child: Obx(() {
        final int unread = notifCtrl.unreadCount.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.yellowg, AppColors.primary],
                ),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.snackBackGroundColor, blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.black),
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: CustomText(
                    text: unread > 99 ? '99+' : '$unread',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  static const Map<TripType, IconData> _tripTypeIcons = {
    TripType.oneWay: Icons.arrow_right_alt,
    TripType.roundTrip: Icons.sync,
    TripType.airportTransfer: Icons.local_airport_outlined,
  };

  Widget _buildTripTypeSelector() {
    return Obx(() {
      final available = _tripTypeIcons.keys.where((t) => tripController.tripData.containsKey(t)).toList();

      if (available.isNotEmpty && !available.contains(tripController.selectedType.value)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tripController.setTripType(available.first));
      }

      return SizedBox(
        width: 330,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Row(
            children: [
              for (int i = 0; i < available.length; i++) ...[
                if (i > 0) 5.width,
                if (available[i] == TripType.oneWay)
                  KeyedSubtree(
                    key: coachTripTypeKey,
                    child: _buildTripTypeItem(available[i], _tripTypeIcons[available[i]]!),
                  )
                else
                  _buildTripTypeItem(available[i], _tripTypeIcons[available[i]]!),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTripTypeItem(TripType type, IconData icon) {
    return Obx(() {
      bool isSelected = tripController.selectedType.value == type;
      String label = tripController.tripData[type]?['name'] ?? '';

      return GestureDetector(
        onTap: () => tripController.setTripType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: AppColors.snackBackGroundColor, blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.grey200),
            gradient: isSelected ? AppColors.gradientButton : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.white : AppColors.grey),
              8.width,
              CustomText(
                text: label,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.white : AppColors.grey,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLocationCard() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          key: coachRouteKey,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.snackBackGroundColor, blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: _railStack(
            children: [
              _buildLocationItem(
                label: 'Pickup Location',
                value: controller.isPickupCurrent ? 'Current Location' : controller.pickupAddress.value,
                icon: Icons.my_location_rounded,
                iconColor: AppColors.primary,
                onTap: () => controller.goToSearch(true),
                trailing: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.grey300),
              ),
              _rowDivider(),
              _buildLocationItem(
                label: 'Destination',
                value: controller.isDestinationCurrent ? 'Current Location' : controller.destinationAddress.value,
                subtitle: '',
                icon: Icons.location_on_rounded,
                iconColor: AppColors.darkSlate,
                onTap: () => controller.goToSearch(false),
                trailing: _buildAddStopTrailing(key: coachAddStopKey),
              ),
              if (controller.stops.isNotEmpty) ...[_rowDivider(), _buildStopsRow()],
            ],
          ),
        ),
      ),
    );
  }

  static const double _railLeft = 28;
  static const double _railStop = 49;

  Widget _railStack({required List<Widget> children}) {
    return Stack(
      children: [
        const Positioned(
          left: _railLeft,
          top: _railStop,
          bottom: _railStop,
          width: 2,
          child: DottedVerticalLine(thickness: 1),
        ),
        Column(children: children),
      ],
    );
  }

  Widget _rowDivider() {
    return Container(margin: const EdgeInsets.only(left: 62, right: 16), height: 1, color: AppColors.grey100);
  }

  Widget _buildStopsRow() {
    final int count = controller.stops.length;
    final String names = controller.stops.map((s) => (s['mainText'] ?? '').toString()).join(', ');

    return _buildLocationItem(
      label: 'Stops',
      value: '$count ${count == 1 ? 'stop' : 'stops'} added',
      subtitle: names,
      icon: Icons.swap_calls_rounded,
      iconColor: AppColors.orangeAccent,
      onTap: StopsReorderSheet.show,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomText(text: 'Manage', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.orangeAccent),
            2.width,
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStopTrailing({Key? key}) {
    return InkWell(
      onTap: controller.stops.length >= 3
          ? () => AppSnackbar.warning('Unable to add', 'Maximum 3 stops are allowed')
          : () async {
              var result = await Get.toNamed(AppRoutes.locationSearch, arguments: 'Stop');
              if (result != null) {
                controller.stops.add(result);
              }
            },
      child: Card(
        elevation: 3,
        child: Container(
          key: key,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppShadows.lg,
          ),
          child: Icon(
            Icons.add_rounded,
            size: 18,
            color: controller.stops.length >= 3 ? AppColors.grey400 : AppColors.orangeAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.27), shape: BoxShape.circle),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(text: label, fontSize: 10, color: AppColors.grey500, fontWeight: FontWeight.w600),
                  3.height,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CustomText(
                      text: value,
                      fontSize: 14,
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  5.height,
                ],
              ),
            ),
            if (trailing != null) ...[10.width, trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildAirportTransferCard() {
    return Obx(() {
      bool isToAirport = controller.isToAirport.value;
      String airportText = controller.selectedTerminal.value != null
          ? '${controller.selectedTerminal.value!.name}, ${controller.selectedAirport.value!.name}'
          : 'Select Airport';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.snackBackGroundColor, blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            CupertinoSlidingSegmentedControl<bool>(
              groupValue: controller.isToAirport.value,
              children: {
                true: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomText(
                    text: "To Airport",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: controller.isToAirport.value ? AppColors.primary : AppColors.black,
                  ),
                ),
                false: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomText(
                    text: "From Airport",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: !controller.isToAirport.value ? AppColors.primary : AppColors.black,
                  ),
                ),
              },
              onValueChanged: (value) {
                if (value == null) return;
                controller.isToAirport.value = value;
                controller.setSelectingPickup(value);
              },
            ),
            16.height,

            _railStack(
              children: [
                if (isToAirport) ...[
                  _buildLocationItem(
                    label: 'Pickup Location',
                    value: controller.isPickupCurrent ? 'Current Location' : controller.pickupAddress.value,
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.primary,
                    onTap: () => controller.goToSearch(true),
                  ),
                  _rowDivider(),
                  _buildLocationItem(
                    label: 'Airport Destination',
                    value: airportText,
                    icon: Icons.local_airport_rounded,
                    iconColor: AppColors.darkSlate,
                    onTap: () {
                      controller.setSelectingPickup(false);
                      Get.bottomSheet(const AirportSelectionBottomSheet(), isScrollControlled: true);
                    },
                    trailing: _buildAddStopTrailing(),
                  ),
                ] else ...[
                  _buildLocationItem(
                    label: 'Airport Pickup',
                    value: airportText,
                    icon: Icons.local_airport_rounded,
                    iconColor: AppColors.primary,
                    onTap: () {
                      controller.setSelectingPickup(true);
                      Get.bottomSheet(const AirportSelectionBottomSheet(), isScrollControlled: true);
                    },
                  ),
                  _rowDivider(),
                  _buildLocationItem(
                    label: 'Destination',
                    value: controller.isDestinationCurrent ? 'Current Location' : controller.destinationAddress.value,
                    subtitle: '',
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.darkSlate,
                    onTap: () => controller.goToSearch(false),
                    trailing: _buildAddStopTrailing(),
                  ),
                ],
                if (controller.stops.isNotEmpty) ...[_rowDivider(), _buildStopsRow()],
              ],
            ),
          ],
        ),
      );
    });
  }
}
