import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/profile/controllers/profile_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/controllers/trip_state_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/trip_type_controller.dart';
import '../../my_trips/controllers/my_trips_controller.dart';
import '../controllers/active_trips_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);
    Get.put(TripController(), permanent: true);
    Get.put(MyTripsController(), permanent: true);
    Get.put(SavedAddressesController(), permanent: true);
    Get.put(ActiveTripsController(), permanent: true);
    Get.put(TripStateController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
  }
}
