import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/legal/controller/legal_controller.dart';
import 'package:orange_taxi_customer_app/features/legal/model/legal_document.dart';

class LegalBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final LegalDocType type = args is LegalDocType ? args : LegalDocType.privacyPolicy;
    Get.put<LegalController>(LegalController(type));
  }
}
