import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';

class ActiveTripsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActiveTripsController>(() => ActiveTripsController());
  }
}
