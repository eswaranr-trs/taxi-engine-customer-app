import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/auth/signup/controller/signup_controller.dart' show SignUpController;

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignUpController>(() => SignUpController());
  }
}
