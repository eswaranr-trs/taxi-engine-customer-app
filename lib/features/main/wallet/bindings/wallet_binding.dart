import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/controller/wallet_controller.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletController>(() => WalletController());
  }
}
