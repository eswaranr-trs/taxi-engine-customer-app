import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/vehicle_selection_controller.dart';
import '../controllers/finding_driver_controller.dart';

class FindingDriverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FindingDriverController>(() => FindingDriverController(), fenix: true);
    Get.lazyPut<VehicleSelectionController>(() => VehicleSelectionController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
