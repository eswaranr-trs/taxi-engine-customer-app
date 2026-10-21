class PromoCodeModel {
  final String promoCodeId;
  final String code;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minBookingAmount;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final double? discountAmount;
  final double? finalAmount;

  PromoCodeModel({
    required this.promoCodeId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minBookingAmount,
    this.startDate,
    this.expiryDate,
    this.discountAmount,
    this.finalAmount,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    double? dn(dynamic v) => v == null ? null : double.tryParse(v.toString());
    return PromoCodeModel(
      promoCodeId: json['promoCodeId']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? 'flat',
      discountValue: d(json['discountValue']),
      maxDiscount: dn(json['maxDiscount']),
      minBookingAmount: d(json['minBookingAmount']),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? ''),
      discountAmount: dn(json['discountAmount']),
      finalAmount: dn(json['finalAmount']),
    );
  }

  bool get isPercentage => discountType.toLowerCase() == 'percentage';

  String get discountLabel =>
      isPercentage ? '${discountValue.toStringAsFixed(0)}% OFF' : '₹${discountValue.toStringAsFixed(0)} OFF';

  bool isEligibleFor(double fare) => fare > 0 && fare >= minBookingAmount;

  double shortfallFor(double fare) => (minBookingAmount - fare).clamp(0, double.infinity);

  double savingsFor(double fare) {
    if (!isEligibleFor(fare)) return 0;
    if (!isPercentage) return discountValue;
    final double raw = fare * discountValue / 100;
    return maxDiscount == null ? raw : (raw > maxDiscount! ? maxDiscount! : raw);
  }
}
