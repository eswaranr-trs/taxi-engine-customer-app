import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/data/repositories/notification_api/notification_repository.dart';
import 'package:orange_taxi_customer_app/features/main/notifications/models/notification_model.dart';

class NotificationsController extends GetxController {
  final NotificationRepository _repo = NotificationRepository();

  final RxList<NotificationModel> items = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  static const String _readKey = 'read_notification_ids';
  final Set<int> _readIds = {};
  bool _readIdsLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _loadReadIds().then((_) => fetchUnreadCount());
  }

  Future<void> _loadReadIds() async {
    if (_readIdsLoaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      _readIds.addAll((p.getStringList(_readKey) ?? []).map(int.tryParse).whereType<int>());
    } catch (_) {}
    _readIdsLoaded = true;
  }

  Future<void> _persistReadIds() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_readKey, _readIds.map((e) => e.toString()).toList());
    } catch (_) {}
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      error.value = null;
      await _loadReadIds();
      final r = await _repo.getNotifications();
      items.assignAll(r.items.map((n) => n.setRead(_readIds.contains(n.id))).toList());
      unreadCount.value = items.where((n) => !n.isRead).length;
    } catch (e) {
      error.value = e is ApiException ? e.message : 'Could not load notifications';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnreadCount() async {
    if (items.isNotEmpty) {
      unreadCount.value = items.where((n) => !n.isRead).length;
      return;
    }
    try {
      unreadCount.value = await _repo.getUnreadCount();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;
    _readIds.addAll(items.map((n) => n.id));
    unawaited(_persistReadIds());
    unreadCount.value = 0;
    items.assignAll(items.map((n) => n.setRead(true)).toList());
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }

  Future<void> markRead(NotificationModel n) async {
    if (n.isRead) return;
    final int index = items.indexWhere((e) => e.id == n.id);
    if (index == -1) return;
    _readIds.add(n.id);
    unawaited(_persistReadIds());
    items[index] = n.setRead(true);
    if (unreadCount.value > 0) unreadCount.value--;
    try {
      await _repo.markRead(n.id);
    } catch (_) {}
  }

  Future<void> delete(NotificationModel n) async {
    final int index = items.indexWhere((e) => e.id == n.id);
    if (index == -1) return;
    items.removeAt(index);
    if (!n.isRead && unreadCount.value > 0) unreadCount.value--;
    try {
      await _repo.deleteNotification(n.id);
    } catch (_) {
      items.insert(index, n);
      if (!n.isRead) unreadCount.value++;
    }
  }
}
