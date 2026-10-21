class NotificationModel {
  final int id;
  final String customerNotificationId;
  final String notificationType;
  final String? bookingId;
  final String title;
  final String body;
  final String status;
  final DateTime? readAt;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.customerNotificationId,
    required this.notificationType,
    this.bookingId,
    required this.title,
    required this.body,
    required this.status,
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  NotificationModel setRead(bool read) => NotificationModel(
    id: id,
    customerNotificationId: customerNotificationId,
    notificationType: notificationType,
    bookingId: bookingId,
    title: title,
    body: body,
    status: status,
    readAt: read ? (readAt ?? DateTime.now()) : null,
    createdAt: createdAt,
  );

  NotificationModel copyWith({DateTime? readAt}) => NotificationModel(
    id: id,
    customerNotificationId: customerNotificationId,
    notificationType: notificationType,
    bookingId: bookingId,
    title: title,
    body: body,
    status: status,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      customerNotificationId: json['customerNotificationId']?.toString() ?? '',
      notificationType: json['notificationType']?.toString() ?? 'General',
      bookingId: json['bookingId']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
