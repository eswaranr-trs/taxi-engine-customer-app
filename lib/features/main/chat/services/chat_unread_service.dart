import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/chat_api/chat_repository.dart';
import 'package:orange_taxi_customer_app/features/main/chat/models/chat_message_model.dart';

class ChatUnreadService extends GetxService with WidgetsBindingObserver {
  final ChatRepository _repo = ChatRepository();

  final RxInt total = 0.obs;
  final RxInt fromDriver = 0.obs;
  final RxInt fromAdmin = 0.obs;

  bool _bound = false;
  Timer? _debounce;

  String? openChatType;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshCounts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshCounts();
  }

  void bindSocket() {
    if (_bound) {
      return;
    }
    _bound = true;
    SocketService().on('chat:message', _onChatMessage);
    SocketService().on('connect', _onSocketConnect);
  }

  void _onSocketConnect(dynamic _) => refreshCounts();

  void _onChatMessage(dynamic data) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), refreshCounts);
    if (data is Map) _notify(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
  }

  void _notify(ChatMessage msg) {
    if (msg.isMe || msg.text.isEmpty) return;
    final String side = msg.senderRole == 'driver' ? 'driver' : 'support';
    if (openChatType == side) return;
    AppSnackbar.info(side == 'driver' ? 'Driver' : 'Support', msg.text);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    SocketService().off('chat:message', _onChatMessage);
    SocketService().off('connect', _onSocketConnect);
    super.onClose();
  }

  Future<void> refreshCounts() async {
    if (!await LocalStorageService.isLoggedIn()) return;
    try {
      final counts = await _repo.getUnreadCounts();
      total.value = counts.total;
      fromDriver.value = counts.fromDriver;
      fromAdmin.value = counts.fromAdmin;
    } catch (_) {}
  }
}
