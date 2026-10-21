import 'dart:convert';
import 'dart:io';
import 'lib/config/translations/languages.dart';

void main() async {
  final languages = Languages();
  final dir = Directory('assets/locales');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  languages.keys.forEach((locale, translations) {
    final file = File('assets/locales/\.json');
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(translations));
  });
}
