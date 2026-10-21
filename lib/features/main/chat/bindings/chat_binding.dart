import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/chat/controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}
