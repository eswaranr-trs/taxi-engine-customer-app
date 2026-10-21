import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/notifications/models/notification_model.dart';

class NotificationRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<({List<NotificationModel> items, int unreadCount})> getNotifications() async {
    try {
      final response = await _apiService.get(AppEndpoints.notifications, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = (response.data['data'] as List?) ?? const [];
        final items = list
            .whereType<Map>()
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final int unread = (response.data['unreadCount'] as num?)?.toInt() ?? 0;
        return (items: items, unreadCount: unread);
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load notifications');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(AppEndpoints.notificationsUnreadCount, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data']?['unreadCount'] as num?)?.toInt() ?? 0;
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load unread count');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      final response = await _apiService.patch(AppEndpoints.notificationsReadAll, data: const {});
      if (response.statusCode == 200 && response.data['success'] == true) return;
      throw ApiException(message: response.data['message'] ?? 'Failed to mark as read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> markRead(dynamic id) async {
    try {
      final response = await _apiService.patch(AppEndpoints.notificationReadById(id), data: const {});
      if (response.statusCode == 200 && (response.data == null || response.data['success'] == true)) return;
      throw ApiException(message: response.data?['message'] ?? 'Failed to mark as read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<({List<String> available, List<String> allowed})> getPreferences() async {
    try {
      final response = await _apiService.get(AppEndpoints.notificationPreferences, requiresToken: true);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] ?? {};
        List<String> ls(String k) => ((data[k] as List?) ?? const []).map((e) => e.toString()).toList();
        return (available: ls('availableNotificationTypes'), allowed: ls('allowedNotificationTypes'));
      }
      throw ApiException(message: response.data['message'] ?? 'Failed to load preferences');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> updatePreferences({List<String> enable = const [], List<String> disable = const []}) async {
    try {
      final response = await _apiService.put(
        AppEndpoints.notificationPreferences,
        data: {'enable': enable, 'disable': disable},
      );
      if (response.statusCode == 200 && response.data['success'] == true) return;
      throw ApiException(message: response.data['message'] ?? 'Failed to save preferences');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> deleteNotification(dynamic id) async {
    try {
      final response = await _apiService.delete(AppEndpoints.notificationById(id));
      if ((response.statusCode == 200 || response.statusCode == 204) &&
          (response.data == null || response.data['success'] == true)) {
        return;
      }
      throw ApiException(message: response.data?['message'] ?? 'Failed to delete notification');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: 'Network Error');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
