import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/auth/welcome/controller/welcome_controller.dart';

class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WelcomeController());
  }
}
