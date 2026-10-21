import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/finding_driver_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/controllers/trip_distance_controller.dart';

class TripInProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FindingDriverController>(() => FindingDriverController(), fenix: true);
    Get.lazyPut<TripDistanceController>(() => TripDistanceController(), fenix: true);
  }
}
