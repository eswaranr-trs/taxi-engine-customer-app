import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/vehicle_selection.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dotted_line/dotted_vertical_line.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/widgets/stops_reorder_sheet.dart';

class RouteSummaryScreen extends StatefulWidget {
  const RouteSummaryScreen({super.key});

  @override
  State<RouteSummaryScreen> createState() => _RouteSummaryScreenState();
}

class _RouteSummaryScreenState extends State<RouteSummaryScreen> with WidgetsBindingObserver {
  final HomeController controller = Get.find<HomeController>();

  static const double _sheetFraction = 0.56;

  // final RxBool _stopsExpanded = false.obs;

  final ValueNotifier<double> _mapBottomPad = ValueNotifier<double>(0);
  static const double _padStepPx = 12;
  static const Duration _refitDelay = Duration(milliseconds: 140);
  Timer? _refitDebounce;
  Worker? _routeWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.setRouteSummaryOpen(true);

    _routeWorker = ever(controller.polylines, (_) {
      if (mounted) _scheduleRefit();
    });

    if (controller.polylines.isEmpty) {
      controller.getRoute().then((_) {
        if (mounted) _fitRouteToScreen();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _fitRouteToScreen();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_mapBottomPad.value == 0) {
      _mapBottomPad.value = MediaQuery.of(context).size.height * _sheetFraction;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refitDebounce?.cancel();
    _routeWorker?.dispose();
    _mapBottomPad.dispose();
    controller.setRouteSummaryOpen(false);
    super.dispose();
  }

  List<LatLng> get _routePoints => [
    for (final line in controller.polylines) ...line.points,
    for (final marker in controller.markers) marker.position,
  ];

  LatLngBounds _boundsFor(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    const double minSpan = 0.004;
    if (maxLat - minLat < minSpan) {
      final mid = (maxLat + minLat) / 2;
      minLat = mid - minSpan / 2;
      maxLat = mid + minSpan / 2;
    }
    if (maxLng - minLng < minSpan) {
      final mid = (maxLng + minLng) / 2;
      minLng = mid - minSpan / 2;
      maxLng = mid + minSpan / 2;
    }

    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  double get _fitPadding {
    final Size screen = MediaQuery.of(context).size;
    final double topPad = MediaQuery.of(context).padding.top + 64;
    final double visibleHeight = (screen.height - topPad - _mapBottomPad.value).clamp(120.0, screen.height);
    final double shortest = visibleHeight < screen.width ? visibleHeight : screen.width;
    return (shortest * 0.18).clamp(32.0, 90.0);
  }

  Future<void> _fitCamera({bool retry = true}) async {
    if (!mounted) return;
    final map = controller.googleMapController;
    if (map == null) return;

    final points = _routePoints;
    if (points.isEmpty) return;

    try {
      await map.animateCamera(CameraUpdate.newLatLngBounds(_boundsFor(points), _fitPadding));
    } catch (_) {
      if (retry) {
        await Future.delayed(const Duration(milliseconds: 400));
        await _fitCamera(retry: false);
      }
    }
  }

  void _scheduleRefit() {
    _refitDebounce?.cancel();
    _refitDebounce = Timer(_refitDelay, () => _fitCamera(retry: false));
  }

  bool _onSheetDrag(DraggableScrollableNotification notification) {
    if (!mounted) return false;

    final double sheetPx = notification.extent * MediaQuery.of(context).size.height;
    final double stepped = (sheetPx / _padStepPx).roundToDouble() * _padStepPx;

    if ((stepped - _mapBottomPad.value).abs() >= _padStepPx) {
      _mapBottomPad.value = stepped;
      _scheduleRefit();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [_buildMapBackground(context), _buildTopOverlay(), _buildDraggableSummarySheet(context)]),
    );
  }

  Future<void> _editLocation(bool isPickup) async {
    final result = await Get.toNamed(AppRoutes.locationSearch, arguments: isPickup ? 'EditPickup' : 'EditDestination');
    if (result is! Map) return;

    final double? lat = (result['lat'] as num?)?.toDouble();
    final double? lng = (result['lng'] as num?)?.toDouble();
    final String addr = (result['mainText'] ?? '').toString();
    if (lat == null || lng == null || addr.isEmpty) return;
    if (controller.rejectIfDuplicate(LatLng(lat, lng), skipPickup: isPickup, skipDestination: !isPickup)) return;

    if (isPickup) {
      controller.pickupLatLng.value = LatLng(lat, lng);
      controller.pickupAddress.value = addr;
    } else {
      controller.destinationLatLng.value = LatLng(lat, lng);
      controller.destinationAddress.value = addr;
    }

    await controller.getRoute();
    _fitRouteToScreen();
  }

  void _fitRouteToScreen() {
    if (!mounted) return;
    _fitCamera();
    Future.delayed(const Duration(milliseconds: 550), () => _fitCamera(retry: false));
  }

  Widget _buildMapBackground(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double topPad = MediaQuery.of(context).padding.top + 64;

    return Obx(() {
      controller.polylines.length;
      controller.markers.length;
      return ValueListenableBuilder<double>(
        valueListenable: _mapBottomPad,
        builder: (context, sheetPx, _) {
          final double bottomPad = sheetPx.clamp(0.0, screen.height * 0.7);

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: controller.pickupLatLng.value, zoom: 12),
            onMapCreated: (c) {
              controller.onMapCreated(c);
              // controller.setMapStyle();
              _fitRouteToScreen();
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
            polylines: controller.polylines.toSet(),
            markers: controller.markers.toSet(),
          );
        },
      );
    });
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableSummarySheet(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(translation: Offset(0, (1 - t) * 0.12), child: child),
      ),
      child: _summarySheet(context),
    );
  }

  Widget _summarySheet(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onSheetDrag,
      child: DraggableScrollableSheet(
        initialChildSize: _sheetFraction,
        minChildSize: _sheetFraction,
        maxChildSize: _sheetFraction,
        snap: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: AppColors.black12, blurRadius: 24, offset: Offset(0, -6))],
            ),
            child: Column(
              children: [
                // Padding(
                //   padding: const EdgeInsets.only(top: 10, bottom: 6),
                //   child: Container(
                //     width: 44,
                //     height: 5,
                //     decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
                //   ),
                // ),
                15.height,
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const CustomText(text: 'Route Summary', fontSize: 19, fontWeight: FontWeight.bold),
                            _buildServiceType(),
                          ],
                        ),
                        16.height,
                        _buildRouteCard(),
                        12.height,
                        Align(
                          alignment: Alignment.centerRight,
                          child: Obx(
                            () => controller.stops.isEmpty ? _buildAddStopButton() : _buildManageStopsButton(),
                          ),
                        ),
                        16.height,
                        _buildMetricsRow(),
                      ],
                    ),
                  ),
                ),
                _buildPinnedFooter(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteCard() {
    return Obx(() {
      // final int stopCount = controller.stops.length;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            _routePoint(
              icon: Icons.my_location_rounded,
              color: AppColors.primary,
              label: 'PICKUP',
              address: controller.pickupAddress.value,
              lineBelow: true,
              onTap: () => _editLocation(true),
            ),
            // if (stopCount > 0) _buildStopsSection(stopCount),
            _routePoint(
              icon: Icons.place_rounded,
              color: AppColors.darkSlate,
              label: 'DESTINATION',
              address: controller.destinationAddress.value,
              lineBelow: false,
              onTap: () => _editLocation(false),
            ),
          ],
        ),
      );
    });
  }

  // Widget _buildStopsSection(int count) {
  //   return Stack(
  //     children: [
  //       const Positioned(left: _badgeSize / 2 - 1, top: 0, bottom: 0, width: 2, child: DottedVerticalLine()),
  //       Padding(
  //         padding: const EdgeInsets.only(left: _badgeSize + 14, bottom: 10),
  //         child: Obx(() {
  //           final bool expanded = _stopsExpanded.value;
  //           return Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               InkWell(
  //                 onTap: _stopsExpanded.toggle,
  //                 borderRadius: BorderRadius.circular(8),
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(vertical: 4),
  //                   child: Row(
  //                     children: [
  //                       CustomText(
  //                         text: 'STOPS ($count)',
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.bold,
  //                         color: AppColors.orangeAccent,
  //                         letterSpacing: 0.6,
  //                       ),
  //                       4.width,
  //                       AnimatedRotation(
  //                         turns: expanded ? 0.5 : 0,
  //                         duration: const Duration(milliseconds: 220),
  //                         curve: Curves.easeOutCubic,
  //                         child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.orangeAccent),
  //                       ),
  //                       const Spacer(),
  //                       if (!expanded)
  //                         Flexible(
  //                           child: CustomText(
  //                             text: controller.stops.map((s) => (s['mainText'] ?? '').toString()).join(', '),
  //                             fontSize: 11,
  //                             color: AppColors.grey400,
  //                             maxLines: 1,
  //                             overflow: TextOverflow.ellipsis,
  //                             textAlign: TextAlign.right,
  //                           ),
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               AnimatedSize(
  //                 duration: const Duration(milliseconds: 220),
  //                 curve: Curves.easeOutCubic,
  //                 alignment: Alignment.topCenter,
  //                 child: expanded
  //                     ? Padding(
  //                         padding: const EdgeInsets.only(top: 8),
  //                         child: Container(
  //                           decoration: BoxDecoration(
  //                             color: AppColors.white,
  //                             borderRadius: BorderRadius.circular(14),
  //                             border: Border.all(color: AppColors.grey100),
  //                           ),
  //                           child: Column(
  //                             children: [
  //                               Column(
  //                                 children: List.generate(
  //                                   controller.stops.length,
  //                                   (index) => _buildStopRow(index, controller.stops[index]),
  //                                 ),
  //                               ),
  //                               Container(height: 1, color: AppColors.grey100),
  //                             ],
  //                           ),
  //                         ),
  //                       )
  //                     : const SizedBox(width: double.infinity),
  //               ),
  //             ],
  //           );
  //         }),
  //       ),
  //     ],
  //   );
  // }

  Future<void> _addStop() async {
    final result = await Get.toNamed(AppRoutes.locationSearch, arguments: 'Stop');
    if (result is! Map) return;

    final double? lat = (result['lat'] as num?)?.toDouble();
    final double? lng = (result['lng'] as num?)?.toDouble();
    if (lat != null && lng != null && controller.rejectIfDuplicate(LatLng(lat, lng))) return;

    controller.stops.add(Map<String, dynamic>.from(result));
  }

  Widget _routePoint({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
    required bool lineBelow,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
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
                      color: AppColors.grey500,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                    3.height,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            text: address,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkSlate,
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        if (onTap != null) ...[
                          8.width,
                          InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.keyboard_arrow_right, size: 18, color: AppColors.grey400),
                            ),
                          ),
                        ],
                      ],
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

  // Widget _buildStopRow(int index, Map<String, dynamic> stop) {
  //   Future<void> editStop() async {
  //     final result = await Get.toNamed(AppRoutes.locationSearch, arguments: 'Stop');
  //     if (result != null) {
  //       controller.stops[index] = result;
  //       controller.stops.refresh();
  //     }
  //   }
  //   return InkWell(
  //     key: ValueKey('stop_$index'),
  //     onTap: editStop,
  //     child: Padding(
  //       padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 22,
  //             height: 22,
  //             decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
  //             child: Center(
  //               child: CustomText(
  //                 text: '${index + 1}',
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.bold,
  //                 color: AppColors.white,
  //               ),
  //             ),
  //           ),
  //           10.width,
  //           Expanded(
  //             child: CustomText(
  //               text: (stop['mainText'] ?? '').toString(),
  //               fontSize: 13.5,
  //               fontWeight: FontWeight.w600,
  //               color: AppColors.grey700,
  //               textAlign: TextAlign.left,
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // static const double _badgeSize = 18;

  Widget _pointBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.8),
        boxShadow: AppShadows.lg,
      ),
      child: Icon(icon, size: 13, color: AppColors.white),
    );
  }

  Widget _buildAddStopButton() {
    return InkWell(
      onTap: _addStop,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.amber600),
            6.width,
            const CustomText(text: 'Add stop', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.amber600),
          ],
        ),
      ),
    );
  }

  Widget _buildManageStopsButton() {
    final int count = controller.stops.length;
    return InkWell(
      onTap: StopsReorderSheet.show,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.amber600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_calls_rounded, size: 16, color: AppColors.amber600),
            6.width,
            CustomText(
              text: 'Manage ${count == 1 ? 'stop' : 'stops'}',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.amber600,
            ),
            2.width,
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.amber600),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.route_outlined,
              label: 'Total Distance',
              value: controller.distance.value,
            ),
          ),
          14.width,
          Expanded(
            child: _buildMetricCard(icon: Icons.schedule, label: 'Est. Time', value: controller.duration.value),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.white, size: 18),
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: label, fontSize: 10, color: AppColors.grey500),
                2.height,
                value.trim().isEmpty
                    ? const Shimmer(child: SkeletonBox(width: 50, height: 15))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CustomText(text: value, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceType() {
    final TripController tripController = Get.find<TripController>();
    return Obx(() {
      final String name = (tripController.tripData[tripController.selectedType.value]?['name'] ?? '').toString();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_taxi, color: AppColors.primary, size: 16),
            8.width,
            name.isEmpty
                ? const Shimmer(child: SkeletonBox(width: 60, height: 12))
                : CustomText(text: name, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ],
        ),
      );
    });
  }

  Widget _buildPinnedFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: CustomButton(
        gradient: AppColors.gradientButton,
        textColor: AppColors.white,
        icon: Icons.arrow_forward,
        text: 'Select Vehicle',
        onPressed: _onSelectVehicle,
      ),
    );
  }

  Future<void> _onSelectVehicle() async {
    final vehicleController = Get.put(VehicleSelectionController());
    if (vehicleController.openingVehicles.value) return;
    vehicleController.openingVehicles.value = true;
    try {
      final tripController = Get.find<TripController>();
      final key = vehicleController.estimationKey(
        pickupLat: controller.pickupLatLng.value.latitude,
        pickupLng: controller.pickupLatLng.value.longitude,
        dropLat: controller.destinationLatLng.value.latitude,
        dropLng: controller.destinationLatLng.value.longitude,
        stops: controller.formattedStops,
        serviceTypeId: tripController.serviceId,
      );

      bool response;
      if (vehicleController.hasFreshEstimation(key)) {
        response = true;
      } else {
        response = await vehicleController.fetchEstimation(
          pickUp: controller.pickupAddress.value,
          drop: controller.destinationAddress.value,
          stops: controller.formattedStops,
          pickupDateTime: DateTime.now(),
          serviceTypeId: tripController.serviceId,
          pickupLat: controller.pickupLatLng.value.latitude,
          pickupLng: controller.pickupLatLng.value.longitude,
          dropLat: controller.destinationLatLng.value.latitude,
          dropLng: controller.destinationLatLng.value.longitude,
        );
      }

      if (response) await _showVehicleSelectionBottomSheet();
    } finally {
      vehicleController.openingVehicles.value = false;
    }
  }

  Future<void> _showVehicleSelectionBottomSheet() async {
    if (!Get.isRegistered<VehicleSelectionController>()) {
      Get.put(VehicleSelectionController());
    }
    await Get.bottomSheet(
      VehicleSelectionBottomSheet(),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );
  }
}
