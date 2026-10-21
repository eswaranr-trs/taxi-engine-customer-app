import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/auth/language/controllers/language_controller.dart';

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LanguageController());
  }
}
