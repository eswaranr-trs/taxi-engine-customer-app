import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import '../../my_trips/controllers/my_trips_controller.dart';
import '../controllers/trip_type_controller.dart';

class VehicleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehicleSelectionController>(() => VehicleSelectionController());
    Get.lazyPut<MyTripsController>(() => MyTripsController());
    Get.lazyPut<TripController>(() => TripController());
  }
}
