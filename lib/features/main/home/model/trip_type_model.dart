class TripTypeModel {
  final int id;
  final String serviceId;
  final String name;
  final String description;
  final String iconUrl;
  final List<String> allowedBookingTypes;
  final bool isActive;

  TripTypeModel({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.allowedBookingTypes,
    required this.isActive,
  });

  factory TripTypeModel.fromJson(Map<String, dynamic> json) {
    return TripTypeModel(
      id: json['id'],
      serviceId: json['serviceId'],
      name: json['name'],
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      allowedBookingTypes: List<String>.from(json['allowedBookingTypes'] ?? []),
      isActive: json['isActive'] ?? false,
    );
  }
}
