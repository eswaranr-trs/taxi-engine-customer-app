import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/chat/models/chat_unread_counts.dart';

class ChatRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<List<Map<String, dynamic>>> getMessages(String tripId, {required String role}) async {
    try {
      final response = await _apiService.get(AppEndpoints.tripMessagesByRole(tripId, role));
      if (response.statusCode == 200) {
        final data = response.data;
        final List rawList = data is List ? data : (data['messages'] ?? data['data'] ?? []);
        return rawList.cast<Map<String, dynamic>>();
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load messages');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<ChatUnreadCounts> getUnreadCounts() async {
    try {
      final response = await _apiService.get(AppEndpoints.tripMessagesUnreadCount);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ChatUnreadCounts.fromJson(Map<String, dynamic>.from(response.data['data']));
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load unread count');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String tripId,
    required String messageText,
    required String receiverRole,
  }) async {
    try {
      final response = await _apiService.post(
        AppEndpoints.tripMessages(tripId),
        data: {'messageText': messageText, 'receiverRole': receiverRole},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['message']);
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to send message');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
