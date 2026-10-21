class OfferModel {
  final String offerId;
  final String title;
  final String? description;
  final String? bannerImageUrl;
  final String discountType; // 'flat' | 'percentage'
  final double discountValue;
  final double? maxDiscount;
  final double minBookingAmount;
  final DateTime? expiryDate;
  final int priority;

  OfferModel({
    required this.offerId,
    required this.title,
    this.description,
    this.bannerImageUrl,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minBookingAmount,
    this.expiryDate,
    this.priority = 0,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
    double? dn(dynamic v) => v == null ? null : double.tryParse(v.toString());
    return OfferModel(
      offerId: json['offerId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Offer',
      description: json['description']?.toString(),
      bannerImageUrl: json['bannerImageUrl']?.toString(),
      discountType: json['discountType']?.toString() ?? 'flat',
      discountValue: d(json['discountValue']),
      maxDiscount: dn(json['maxDiscount']),
      minBookingAmount: d(json['minBookingAmount']),
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? ''),
      priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
    );
  }

  String get discountLabel => discountType.toLowerCase() == 'percentage'
      ? '${discountValue.toStringAsFixed(0)}% OFF'
      : '₹${discountValue.toStringAsFixed(0)} OFF';

  String get minBookingLabel => 'Min booking ₹${minBookingAmount.toStringAsFixed(0)}';
}
