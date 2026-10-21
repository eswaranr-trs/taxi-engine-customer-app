class ChatUnreadCounts {
  final int total;
  final int fromDriver;
  final int fromAdmin;

  const ChatUnreadCounts({this.total = 0, this.fromDriver = 0, this.fromAdmin = 0});

  factory ChatUnreadCounts.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return ChatUnreadCounts(
      total: n(json['total']),
      fromDriver: n(json['fromDriver']),
      fromAdmin: n(json['fromAdmin']),
    );
  }
}
