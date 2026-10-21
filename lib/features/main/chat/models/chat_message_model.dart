class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;
  final String? avatarUrl;
  final String senderRole;
  final String receiverRole;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.avatarUrl,
    this.senderRole = 'customer',
    this.receiverRole = 'driver',
    this.isRead = false,
  });

  ChatMessage copyWith({bool? isRead}) => ChatMessage(
    id: id,
    text: text,
    isMe: isMe,
    time: time,
    avatarUrl: avatarUrl,
    senderRole: senderRole,
    receiverRole: receiverRole,
    isRead: isRead ?? this.isRead,
  );

  /// Build from API message object. Accepts both snake_case (REST list) and
  /// camelCase (socket) keys. [avatarUrl] for incoming (non-customer) msgs.
  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? avatarUrl}) {
    dynamic pick(String snake, String camel) => json[snake] ?? json[camel];

    final senderRole = pick('sender_role', 'senderRole')?.toString() ?? '';
    final isMe = senderRole == 'customer';
    return ChatMessage(
      id: pick('message_id', 'messageId')?.toString() ?? '',
      text: pick('message_text', 'messageText')?.toString() ?? '',
      isMe: isMe,
      time: DateTime.tryParse(pick('created_at', 'createdAt')?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      avatarUrl: isMe ? null : avatarUrl,
      senderRole: senderRole,
      receiverRole: pick('receiver_role', 'receiverRole')?.toString() ?? '',
      isRead: pick('read_at', 'readAt') != null,
    );
  }
}
