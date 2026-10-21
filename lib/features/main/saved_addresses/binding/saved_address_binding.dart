import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';

class SavedAddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SavedAddressesController>(() => SavedAddressesController());
  }
}
