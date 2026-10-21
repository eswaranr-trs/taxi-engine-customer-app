import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getAuthToken() async {
    print("token   ${await _storage.read(key: _tokenKey)}");
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final String? userData = await _storage.read(key: _userKey);

    if (userData != null) {
      return jsonDecode(userData) as Map<String, dynamic>;
    }

    return null;
  }

  static Future<void> saveResponseData(Map<String, dynamic> response) async {
    final dynamic raw = response['data'];
    final Map<String, dynamic> data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    final String token = (data['token'] ?? data['accessToken'] ?? response['token'] ?? '').toString();
    if (token.isNotEmpty) {
      await saveAuthToken(token);
    }

    final String refresh = (data['refreshToken'] ?? response['refreshToken'] ?? '').toString();
    if (refresh.isNotEmpty) {
      await saveRefreshToken(refresh);
    }

    final dynamic user = data['user'];
    if (user is Map) {
      await saveUserData(Map<String, dynamic>.from(user));
    }
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
