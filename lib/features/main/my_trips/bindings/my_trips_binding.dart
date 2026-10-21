import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import '../controllers/my_trips_controller.dart';

class MyTripsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripsRepository>(() => TripsRepository());
    Get.lazyPut<MyTripsController>(() => MyTripsController());
  }
}
