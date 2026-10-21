import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/offers/controllers/offers_controller.dart';

class OffersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OffersController>(() => OffersController());
  }
}
