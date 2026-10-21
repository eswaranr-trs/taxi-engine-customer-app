import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/data/repositories/enquiry_api/enquiry_repository.dart';
import 'core/services/network_service/api_service.dart';
import 'core/services/network_service/connectivity_service.dart';
import 'data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/features/main/chat/services/chat_unread_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ConnectivityService(), permanent: true);
    Get.put(ApiService(), permanent: true);
    Get.put(AuthRepository(), permanent: true);
    Get.put(TripStateService(), permanent: true);
    Get.put(EnquiryRepository(), permanent: true);
    Get.put(ChatUnreadService(), permanent: true);
  }
}
