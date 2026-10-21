class UserProfile {
  final int id;
  final String customerId;
  final String name;
  final String phone;
  final String email;
  final String? dateOfBirth;
  final String signUpMethod;
  final String language;
  final bool marketingConsent;
  final double rating;
  final int totalBookings;
  final String memberYears;
  final String avatarUrl;
  final bool isVerified;
  final String? createdAt;
  final String referralCode;

  int get ridesCount => totalBookings;

  static const String _defaultAvatar = '';

  UserProfile({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    this.dateOfBirth,
    required this.signUpMethod,
    required this.language,
    required this.marketingConsent,
    required this.rating,
    required this.totalBookings,
    required this.memberYears,
    required this.avatarUrl,
    required this.isVerified,
    this.createdAt,
    this.referralCode = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      customerId: json['customerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'No name',
      phone: json['phone']?.toString() ?? 'No number',
      email: json['email']?.toString() ?? 'No email',
      dateOfBirth: json['dateOfBirth']?.toString(),
      signUpMethod: json['signUpMethod']?.toString() ?? 'phone',
      language: json['language']?.toString() ?? 'en',
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      rating: double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      totalBookings: int.tryParse(json['totalBookings']?.toString() ?? '0') ?? 0,
      memberYears: _memberSince(json['createdAt']?.toString()),
      avatarUrl: (json['profileImageUrl'] ?? json['avatarUrl'])?.toString().isNotEmpty == true
          ? (json['profileImageUrl'] ?? json['avatarUrl']).toString()
          : _defaultAvatar,
      isVerified: json['isActive'] as bool? ?? false,
      createdAt: json['createdAt']?.toString(),
      referralCode: json['referralCode']?.toString() ?? '',
    );
  }

  static String _memberSince(String? createdAt) {
    if (createdAt == null) return '-';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '-';
    return dt.year.toString();
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? dateOfBirth,
    bool? marketingConsent,
    double? rating,
    int? totalBookings,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id,
      customerId: customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      signUpMethod: signUpMethod,
      language: language,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      rating: rating ?? this.rating,
      totalBookings: totalBookings ?? this.totalBookings,
      memberYears: memberYears,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      referralCode: referralCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'name': name,
      'phone': phone,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'signUpMethod': signUpMethod,
      'language': language,
      'marketingConsent': marketingConsent,
      'averageRating': rating,
      'totalBookings': totalBookings,
      'avatarUrl': avatarUrl,
      'isActive': isVerified,
      'createdAt': createdAt,
      'referralCode': referralCode,
    };
  }
}
