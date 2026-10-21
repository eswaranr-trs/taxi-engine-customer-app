class AddressModel {
  final String id;
  final String nickname;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String type;
  final int order;

  AddressModel({
    required this.id,
    required this.nickname,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.notes,
    required this.type,
    required this.order,
  });

  bool get isPersisted => id.isNotEmpty;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['nickname'] ?? '').toString();
    final lower = title.toLowerCase();
    final derivedType = lower == 'home' ? 'home' : (lower == 'work' ? 'work' : 'custom');
    return AddressModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      nickname: title,
      fullAddress: (json['address'] ?? json['fullAddress'] ?? '').toString(),
      latitude: (json['lat'] ?? json['latitude'] as num?)?.toDouble(),
      longitude: (json['lng'] ?? json['longitude'] as num?)?.toDouble(),
      notes: json['notes'],
      type: json['type']?.toString() ?? derivedType,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toApiBody() {
    return {'title': nickname, 'address': fullAddress, 'lat': latitude, 'lng': longitude};
  }

  AddressModel copyWith({
    String? id,
    String? nickname,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? notes,
    String? type,
    int? order,
  }) {
    return AddressModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      order: order ?? this.order,
    );
  }
}
