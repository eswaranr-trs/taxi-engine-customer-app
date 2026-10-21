import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/chat_api/chat_repository.dart';
import 'package:orange_taxi_customer_app/features/main/chat/models/chat_message_model.dart';
import 'package:orange_taxi_customer_app/features/main/chat/services/chat_unread_service.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  final ChatRepository _repo = ChatRepository();

  final RxString chatType = 'support'.obs;
  final RxString selectedOption = 'support'.obs;

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String _tripId = '';
  String get title => chatType.value == 'driver' ? 'Driver' : 'Support';

  String get peerName {
    if (chatType.value == 'driver') {
      final n = Get.isRegistered<TripStateService>() ? Get.find<TripStateService>().selectedTrip?.driverName : null;
      return (n != null && n.isNotEmpty && n != '0') ? n : 'Driver';
    }
    return 'Support';
  }

  String? get peerAvatar => _peerAvatar;

  String get peerPhone {
    if (chatType.value != 'driver') return '';
    final p = Get.isRegistered<TripStateService>() ? Get.find<TripStateService>().selectedTrip?.driverPhone : null;
    return p?.trim() ?? '';
  }

  String get _receiverRole => chatType.value == 'driver' ? 'driver' : 'admin';
  Set<String> get _peerRoles => chatType.value == 'driver' ? {'driver'} : {'admin'};

  bool _belongsHere(ChatMessage m) => _peerRoles.contains(m.senderRole) || _peerRoles.contains(m.receiverRole);
  String? get _peerAvatar {
    if (chatType.value == 'driver') {
      final img = Get.isRegistered<TripStateService>() ? Get.find<TripStateService>().selectedTrip?.driverImage : null;
      return (img != null && img.isNotEmpty) ? img : null;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['type'] is String) chatType.value = args['type'];
      if (args['tripId'] is String) _tripId = args['tripId'];
    }
    if (_tripId.isEmpty && Get.isRegistered<TripStateService>()) {
      _tripId = Get.find<TripStateService>().selectedBookingId.value;
    }
    Get.find<ChatUnreadService>().openChatType = chatType.value == 'driver' ? 'driver' : 'support';
    WidgetsBinding.instance.addObserver(this);
    fetchMessages();
    _listenIncoming();
  }

  void _listenIncoming() {
    SocketService().on('chat:message', _onIncomingMessage);
    SocketService().on('chat:read', _onReadReceipt);
    SocketService().on('connect', _onSocketConnect);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _resync();
  }

  void _onSocketConnect(dynamic _) => _resync();

  DateTime? _lastSyncAt;
  static const Duration _resyncCooldown = Duration(seconds: 2);

  Future<void> _resync() async {
    final now = DateTime.now();
    if (_lastSyncAt != null && now.difference(_lastSyncAt!) < _resyncCooldown) return;
    _lastSyncAt = now;
    if (Get.isRegistered<TripStateService>()) {
      await Get.find<TripStateService>().ensureConnected();
    }
    await fetchMessages();
    Get.find<ChatUnreadService>().refreshCounts();
  }

  void _onReadReceipt(dynamic data) {
    if (data is! Map) return;
    final tripId = data['tripId']?.toString() ?? '';
    if (_tripId.isNotEmpty && tripId.isNotEmpty && tripId != _tripId) return;
    final ids = (data['messageIds'] as List?)?.map((e) => e.toString()).toSet();
    if (ids == null || ids.isEmpty) return;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.isMe && !m.isRead && ids.contains(m.id)) {
        messages[i] = m.copyWith(isRead: true);
      }
    }
    messages.refresh();
  }

  void _onIncomingMessage(dynamic data) {
    if (data is! Map) return;

    final tripId = (data['tripId'] ?? data['trip_id'])?.toString() ?? '';
    if (_tripId.isNotEmpty && tripId.isNotEmpty && tripId != _tripId) return;

    final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data), avatarUrl: _peerAvatar);
    if (!_belongsHere(msg)) return;
    if (msg.isMe) return;
    if (msg.id.isNotEmpty && messages.any((m) => m.id == msg.id)) return;
    messages.add(msg);
    _scrollToBottom();
  }

  void selectOption(String option) => selectedOption.value = option;

  Future<void> fetchMessages() async {
    if (_tripId.isEmpty || isLoading.value) return;
    try {
      isLoading.value = true;
      final raw = await _repo.getMessages(_tripId, role: _receiverRole);
      final list = raw.map((m) => ChatMessage.fromJson(m, avatarUrl: _peerAvatar)).where(_belongsHere).toList();
      list.sort((a, b) => a.time.compareTo(b.time));
      messages.assignAll(list);
      _scrollToBottom();
    } catch (e) {
      AppSnackbar.error('Error', 'Could not load messages');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get quickReplies => chatType.value == 'driver'
      ? const ["I'm at the pickup point", 'On my way', 'Please wait 5 minutes', 'Where are you?', 'Please call me']
      : const ['I need help with my trip', 'I have a payment issue', 'I left an item in the cab', 'Report a problem'];

  Future<void> sendMessage() async {
    await _send(messageController.text.trim(), fromInput: true);
  }

  Future<void> sendQuickReply(String text) async {
    await _send(text.trim(), fromInput: false);
  }

  Future<void> _send(String text, {required bool fromInput}) async {
    if (text.isEmpty || isSending.value) return;
    if (_tripId.isEmpty) {
      AppSnackbar.error('Error', 'No active trip');
      return;
    }

    if (fromInput) messageController.clear();
    isSending.value = true;
    try {
      final sent = await _repo.sendMessage(tripId: _tripId, messageText: text, receiverRole: _receiverRole);
      messages.add(ChatMessage.fromJson(sent, avatarUrl: _peerAvatar));
      _scrollToBottom();
    } catch (e) {
      AppSnackbar.error('Error', 'Message not sent');
      if (fromInput) messageController.text = text;
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.find<ChatUnreadService>().openChatType = null;
    Get.find<ChatUnreadService>().refreshCounts();
    SocketService().off('chat:message', _onIncomingMessage);
    SocketService().off('chat:read', _onReadReceipt);
    SocketService().off('connect', _onSocketConnect);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
