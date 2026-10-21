import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/location_search_controller.dart';

class LocationSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationSearchController>(() => LocationSearchController());
  }
}
