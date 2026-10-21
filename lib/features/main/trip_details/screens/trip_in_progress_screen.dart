import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/finding_driver_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/widgets/driver_trip_details_sheet.dart';

class TripInProgressScreen extends StatefulWidget {
  const TripInProgressScreen({super.key});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen> with WidgetsBindingObserver {
  final FindingDriverController controller = Get.find<FindingDriverController>();

  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _sideControlsKey = GlobalKey();
  final ValueNotifier<EdgeInsets> _mapInsets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  static const Duration _settleDelay = Duration(milliseconds: 180);
  static const double _minVisibleMapFraction = 0.3;
  Timer? _refitDebounce;
  Worker? _routeWorker;
  Worker? _legWorker;
  int _resumeSeq = 0;
  int _lastLeg = 1;
  bool _pendingLegRefit = false;

  double _sheetFraction = 0.5;
  bool _userMovedCamera = false;
  bool _programmaticMove = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.ensureDeviceLocationUpdates();
    controller.resetInProgressRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeInsets());
    final tripState = Get.find<TripStateService>();
    _lastLeg = tripState.selectedLeg;
    _legWorker = ever(tripState.activeTrips, (_) {
      if (!mounted) return;
      final int leg = tripState.selectedLeg;
      if (leg == _lastLeg) return;
      _lastLeg = leg;
      _pendingLegRefit = true;
      _userMovedCamera = false;
      _scheduleRefit(force: true);
    });
    _routeWorker = ever(controller.polylines, (_) {
      if (!mounted || !_pendingLegRefit) return;
      _pendingLegRefit = false;
      _userMovedCamera = false;
      _scheduleRefit(force: true);
    });
    controller.drawInProgressRoute().then((_) {
      if (mounted) _fitCamera(force: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final int seq = ++_resumeSeq;
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted || seq != _resumeSeq) return;
      await controller.refreshAfterResume();
      if (!mounted || seq != _resumeSeq) return;
      _recomputeInsets();
      _userMovedCamera = false;
      _fitCamera(force: true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && seq == _resumeSeq) _fitCamera(force: true, retry: false);
      });
    });
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recomputeInsets();
      _scheduleRefit(force: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recomputeInsets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refitDebounce?.cancel();
    _routeWorker?.dispose();
    _legWorker?.dispose();
    _mapInsets.dispose();
    super.dispose();
  }

  double _measure(GlobalKey key, {required bool width}) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    return width ? box.size.width : box.size.height;
  }

  void _recomputeInsets() {
    if (!mounted) return;
    final media = MediaQuery.of(context);
    final Size size = media.size;
    final double gutter = size.shortestSide * 0.04;

    final double topInset = media.padding.top + _measure(_backButtonKey, width: false) + gutter;
    final double rightInset = _measure(_sideControlsKey, width: true) + gutter;
    final double maxBottom = (size.height - topInset - size.height * _minVisibleMapFraction).clamp(
      0.0,
      size.height * 0.75,
    );
    final double bottomInset = (size.height * _sheetFraction).clamp(0.0, maxBottom);

    final next = EdgeInsets.fromLTRB(gutter, topInset, rightInset, bottomInset);
    if (next == _mapInsets.value) return;
    _mapInsets.value = next;
  }

  void _scheduleRefit({bool force = false}) {
    _refitDebounce?.cancel();
    _refitDebounce = Timer(_settleDelay, () => _fitCamera(force: force));
  }

  List<LatLng> get _routePoints {
    final tripState = Get.find<TripStateService>();
    final points = <LatLng>[for (final line in controller.polylines) ...line.points];

    final current = controller.deviceLocation.value ?? tripState.driverLocation.value;
    if (current != null) points.add(current);

    final target = tripState.activeDestinationFor(null);
    if (target != null) points.add(target);
    return points;
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    const double minSpan = 0.004; // ~450 m
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

  double get _breathingRoom {
    final Size size = MediaQuery.of(context).size;
    final EdgeInsets insets = _mapInsets.value;
    final double visibleH = size.height - insets.top - insets.bottom;
    final double visibleW = size.width - insets.left - insets.right;
    final double shortest = (visibleH < visibleW ? visibleH : visibleW).clamp(1.0, size.longestSide);
    final double maxPad = size.shortestSide * 0.05;
    final double pad = shortest * 0.12;
    return pad < maxPad ? pad : maxPad;
  }

  Future<void> _fitCamera({bool force = false, bool retry = true}) async {
    if (!mounted) return;
    if (!force && _userMovedCamera) return;

    final map = controller.mapController;
    if (map == null) return;

    final points = _routePoints;
    if (points.isEmpty) return;

    _programmaticMove = true;
    try {
      await map.animateCamera(CameraUpdate.newLatLngBounds(_boundsFor(points), _breathingRoom));
      if (force) _userMovedCamera = false;
    } catch (_) {
      if (retry) {
        await Future.delayed(const Duration(milliseconds: 400));
        await _fitCamera(force: force, retry: false);
      }
    }
  }

  void _fitRouteToScreen() {
    if (!mounted) return;
    _recomputeInsets();
    _fitCamera(force: true);
    Future.delayed(const Duration(milliseconds: 550), () => _fitCamera(force: true, retry: false));
  }

  bool _onSheetDrag(DraggableScrollableNotification notification) {
    if (!mounted) return false;
    _onSheetExtent(notification.extent);
    return false;
  }

  void _onSheetExtent(double extent) {
    if (!mounted) return;
    final double minDelta = MediaQuery.of(context).size.height * 0.01;
    if (((extent - _sheetFraction).abs() * MediaQuery.of(context).size.height) < minDelta) return;

    _sheetFraction = extent;
    _recomputeInsets();
    _scheduleRefit(force: true);
  }

  GoogleMapController? googleMapController;

  Future<void> setMapStyle([GoogleMapController? mapController]) async {
    final controller = mapController ?? googleMapController;
    if (controller == null) return;
    try {
      final style = await rootBundle.loadString('assets/map_style.json');
      // ignore: deprecated_member_use
      await controller.setMapStyle(style);
    } catch (_) {}
  }

  void _handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Key? key}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: key,
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
            onPressed: () => controller.zoomIn(),
          ),
          Container(width: 20, height: 1, color: AppColors.grey200),
          IconButton(
            icon: const Icon(Icons.remove, color: AppColors.darkSlate, size: 20),
            onPressed: () => controller.zoomOut(),
          ),
        ],
      ),
    );
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
        body: Stack(
          children: [
            Obx(() {
              final tripState = Get.find<TripStateService>();
              final polylines = controller.polylines.toSet();
              final bool onReturnLeg = tripState.selectedLeg >= 2;
              final markers = controller.markers
                  .where(
                    (m) =>
                        m.markerId.value != 'pickup' &&
                        m.markerId.value != 'destination' &&
                        m.markerId.value != 'driver_location' &&
                        !(onReturnLeg && m.markerId.value.startsWith('stop_')),
                  )
                  .toSet();
              final currentLocation = controller.deviceLocation.value ?? tripState.driverLocation.value;
              if (currentLocation != null) {
                markers.add(
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: currentLocation,
                    icon:
                        controller.currentLocationIcon.value ??
                        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    anchor: const Offset(0.5, 0.5),
                    flat: true,
                    infoWindow: const InfoWindow(title: 'Current Location'),
                  ),
                );
              }
              final bool returnLeg = tripState.isSelectedRoundTrip && tripState.selectedLeg >= 2;
              final LatLng? target = tripState.activeDestinationFor(null);
              if (target != null) {
                markers.add(
                  Marker(
                    markerId: const MarkerId('destination'),
                    position: target,
                    icon:
                        controller.destinationIcon.value ??
                        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(title: returnLeg ? 'Back to Pickup' : 'Destination'),
                  ),
                );
              }
              return ValueListenableBuilder<EdgeInsets>(
                valueListenable: _mapInsets,
                builder: (context, insets, _) {
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentLocation ?? const LatLng(11.0168, 76.9558),
                      zoom: 12,
                    ),
                    onMapCreated: (c) {
                      controller.onMapCreated(c);
                      // setMapStyle(c);
                      _fitRouteToScreen();
                    },
                    onCameraMoveStarted: () {
                      if (!_programmaticMove) _userMovedCamera = true;
                    },
                    onCameraIdle: () => _programmaticMove = false,
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    padding: insets,
                  );
                },
              );
            }),

            NotificationListener<DraggableScrollableNotification>(
              onNotification: _onSheetDrag,
              child: DriverDetailBottomSheet(
                driverData: controller.driverDetails,
                onCall: controller.openDialer,
                onMessage: () => Get.toNamed(AppRoutes.chat, arguments: {'type': 'support'}),
                onExtent: _onSheetExtent,
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _circleButton(Icons.arrow_back, _handleBack, key: _backButtonKey),

                    Column(
                      key: _sideControlsKey,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        50.height,
                        _circleButton(Icons.my_location, () => controller.centerOnUser()),
                        12.height,
                        _zoomControls(),
                        12.height,
                        InkWell(
                          onTap: () {
                            Get.toNamed(AppRoutes.sos);
                          },
                          child: Container(
                            height: 45,
                            width: 45,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
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
          ],
        ),
      ),
    );
  }
}
