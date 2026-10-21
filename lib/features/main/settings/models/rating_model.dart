class RatingModel {
  final int id;
  final String ratingId;
  final String bookingId;
  final String ratedBy;
  final int rating;
  final String review;
  final String driverName;
  final String serviceType;
  final DateTime? createdAt;

  RatingModel({
    required this.id,
    required this.ratingId,
    required this.bookingId,
    required this.ratedBy,
    required this.rating,
    required this.review,
    required this.driverName,
    required this.serviceType,
    this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      ratingId: json['ratingId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      ratedBy: json['ratedBy']?.toString() ?? '',
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      review: json['review']?.toString() ?? '',
      driverName: (json['driverName']?.toString() ?? '').trim(),
      serviceType: json['serviceType']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
