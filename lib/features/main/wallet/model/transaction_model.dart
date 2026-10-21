class TransactionModel {
  final String transactionId;
  final double amount;
  final String transactionType;
  final String type;
  final DateTime date;
  final String reason;
  final String description;
  final String status;

  TransactionModel({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    required this.type,
    required this.date,
    required this.reason,
    required this.description,
    required this.status,
  });

  TransactionModel copyWith({
    String? transactionId,
    double? amount,
    String? transactionType,
    String? type,
    DateTime? date,
    String? reason,
    String? description,
    String? status,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      type: type ?? this.type,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  TransactionModel fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transactionId'] ?? '',
      amount: map['amount'] ?? 0,
      transactionType: map['transactionType'] ?? '',
      type: map['type'] ?? '',
      date: map['date'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
    );
  }
}
