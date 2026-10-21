enum LegalDocType { privacyPolicy, termsAndConditions }

class LegalDocument {
  final String title;
  final String content; // HTML
  final DateTime? lastUpdatedAt;

  const LegalDocument({required this.title, required this.content, this.lastUpdatedAt});

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      title: json['title']?.toString() ?? json['label']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      lastUpdatedAt: DateTime.tryParse(json['lastUpdatedAt']?.toString() ?? '')?.toLocal(),
    );
  }
}
