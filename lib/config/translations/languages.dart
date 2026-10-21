import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Languages extends Translations {
  static final Map<String, Map<String, String>> _keys = {};

  static Future<void> init() async {
    final locales = ['en_US', 'hi_IN', 'ta_IN', 'te_IN', 'kn_IN', 'bn_IN', 'mr_IN', 'gu_IN', 'ar_AE'];

    for (var locale in locales) {
      try {
        final jsonString = await rootBundle.loadString('assets/locales/$locale.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _keys[locale] = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {}
    }
  }

  @override
  Map<String, Map<String, String>> get keys => _keys;
}
