import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';

class TripStateController extends GetxController {
  late final TripStateService _tripStateService;

  @override
  void onInit() {
    super.onInit();
    _tripStateService = Get.find<TripStateService>();

    ever(_tripStateService.activeStages, (_) => _handleRideStageChange(_tripStateService.selectedStage));
    ever(_tripStateService.selectedBookingId, (_) => _handleRideStageChange(_tripStateService.selectedStage));
  }

  void _handleRideStageChange(RideStage stage) {
    if (_tripStateService.suppressAutoNav) return;

    if (_tripStateService.isAutoNavMuted(_tripStateService.selectedBookingId.value)) return;
    final currentRoute = Get.currentRoute;

    switch (stage) {
      case RideStage.findingDriver:
        if (currentRoute != AppRoutes.findingDriver) {
          Get.offNamedUntil(AppRoutes.findingDriver, (route) => route.settings.name == AppRoutes.home);
        }
        break;
      case RideStage.tripVerification:
        if (currentRoute != AppRoutes.tripVerification) {
          Get.offNamedUntil(AppRoutes.tripVerification, (route) => route.settings.name == AppRoutes.home);
        }
        break;
      case RideStage.tripCompleted:
        if (currentRoute != AppRoutes.tripFinished) {
          Get.offNamedUntil(AppRoutes.tripFinished, (route) => route.settings.name == AppRoutes.home);
        }
        break;
      case RideStage.tripCancelled:
        if (currentRoute != AppRoutes.findingDriver) {
          Get.offNamedUntil(AppRoutes.findingDriver, (route) => route.settings.name == AppRoutes.home);
        }
        break;
      case RideStage.tripInProgress:
        if (currentRoute != AppRoutes.tripInProgress) {
          Get.offNamedUntil(AppRoutes.tripInProgress, (route) => route.settings.name == AppRoutes.home);
        }
        break;
      case RideStage.payment:
        if (currentRoute != AppRoutes.paymentScreen) {
          Get.offNamedUntil(AppRoutes.paymentScreen, (route) => route.settings.name == AppRoutes.home);
        }
        break;
      case RideStage.none:
        if (currentRoute == AppRoutes.findingDriver ||
            currentRoute == AppRoutes.tripVerification ||
            currentRoute == AppRoutes.tripInProgress ||
            currentRoute == AppRoutes.paymentScreen ||
            currentRoute == AppRoutes.tripFinished) {
          if (Get.isRegistered<HomeController>()) Get.find<HomeController>().resetTripSelection();
          Get.offAllNamed(AppRoutes.home);
        }
        break;
    }
  }
}
