import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/payment/controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentController>(() => PaymentController());
  }
}
