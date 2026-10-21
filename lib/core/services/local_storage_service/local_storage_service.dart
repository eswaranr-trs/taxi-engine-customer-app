import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';

class LocalStorageService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _languageKey = 'selected_language';
  static const String _hasSelectedLanguageKey = 'has_selected_language';
  static const String _isNewUser = 'is_new_user';
  static const String _isSignupUser = 'is_signup_user';

  static const String _lastActiveKey = 'last_active';

  static const String _loginBlockTimeKey = 'login_block_time';
  static const String _signupBlockTimeKey = 'signup_block_time';

  static Future<void> setIsNewUser(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isNewUser, value);
  }

  static Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isNewUser) ?? true;
  }

  static Future<void> setIsSignupUser(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSignupUser, value);
  }

  static Future<bool> isSignupUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSignupUser) ?? false;
  }

  static Future<void> setSeenCoachMark(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_coach_$screen', true);
  }

  static Future<bool> hasSeenCoachMark(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_coach_$screen') ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    await prefs.setBool(_hasSelectedLanguageKey, true);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  static Future<bool> hasSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSelectedLanguageKey) ?? false;
  }

  static const String _recentSearchesKey = 'recent_searches';

  static Future<void> saveRecentSearch(Map<String, dynamic> searchData) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await getRecentSearches();

    searches.removeWhere((s) {
      final sPlaceId = s['placeId']?.toString();
      final searchPlaceId = searchData['placeId']?.toString();
      final sMainText = s['mainText']?.toString().trim().toLowerCase();
      final searchMainText = searchData['mainText']?.toString().trim().toLowerCase();

      bool placeIdMatch = sPlaceId != null && searchPlaceId != null && sPlaceId == searchPlaceId;
      bool textMatch =
          sMainText != null && searchMainText != null && sMainText.isNotEmpty && sMainText == searchMainText;

      return placeIdMatch || textMatch;
    });

    searches.insert(0, searchData);

    if (searches.length > 5) {
      searches.removeRange(5, searches.length);
    }

    await prefs.setString(_recentSearchesKey, jsonEncode(searches));
  }

  static Future<List<Map<String, dynamic>>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searchesStr = prefs.getString(_recentSearchesKey);
    if (searchesStr != null) {
      final List decoded = jsonDecode(searchesStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  static Future<void> removeRecentSearch(Map<String, dynamic> searchData) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await getRecentSearches();

    final searchPlaceId = searchData['placeId']?.toString();
    final searchMainText = searchData['mainText']?.toString().trim().toLowerCase();

    searches.removeWhere((s) {
      final sPlaceId = s['placeId']?.toString();
      final sMainText = s['mainText']?.toString().trim().toLowerCase();
      final placeIdMatch = sPlaceId != null && searchPlaceId != null && sPlaceId == searchPlaceId;
      final textMatch =
          sMainText != null && searchMainText != null && sMainText.isNotEmpty && sMainText == searchMainText;
      return placeIdMatch || textMatch;
    });

    await prefs.setString(_recentSearchesKey, jsonEncode(searches));
  }

  static const String _savedAddressesKey = 'saved_addresses';

  static Future<void> saveSavedAddress(String type, Map<String, dynamic> addressData) async {
    final prefs = await SharedPreferences.getInstance();
    final addresses = await getSavedAddresses();
    addresses[type] = addressData;
    await prefs.setString(_savedAddressesKey, jsonEncode(addresses));
  }

  static Future<Map<String, Map<String, dynamic>>> getSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_savedAddressesKey);
    if (str != null) {
      final Map<String, dynamic> decoded = jsonDecode(str);
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    }
    return {};
  }

  static const String _serviceTypesKey = 'service_types';

  static Future<void> saveServiceTypes(List<dynamic> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serviceTypesKey, jsonEncode(services));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getServiceTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_serviceTypesKey);
      if (str == null || str.isEmpty) return [];
      final decoded = jsonDecode(str);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static const String _hasGivenConsentKey = 'has_given_consent';
  static const String _consentDataKey = 'consent_data';

  static Future<void> saveConsentData(String ipAddress, String timestamp, String policyVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasGivenConsentKey, true);

    final consentData = {
      'ip_address': ipAddress,
      'timestamp': timestamp,
      'policy_version': policyVersion,
      'dpdp_act_2023_compliant': true,
    };

    await prefs.setString(_consentDataKey, jsonEncode(consentData));
  }

  static Future<Map<String, dynamic>?> getConsentData() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_consentDataKey);
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> hasGivenConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasGivenConsentKey) ?? false;
  }

  static Future<void> setLoginBlockTime(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setString(_loginBlockTimeKey, time.toIso8601String());
    } else {
      await prefs.remove(_loginBlockTimeKey);
    }
  }

  static Future<DateTime?> getLoginBlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_loginBlockTimeKey);
    if (str != null) {
      return DateTime.tryParse(str);
    }
    return null;
  }

  static Future<void> setSignupBlockTime(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setString(_signupBlockTimeKey, time.toIso8601String());
    } else {
      await prefs.remove(_signupBlockTimeKey);
    }
  }

  static Future<DateTime?> getSignupBlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_signupBlockTimeKey);
    if (str != null) {
      return DateTime.tryParse(str);
    }
    return null;
  }

  static Future<void> saveLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int?> getLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_lastActiveKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await SecureStorageService.clear();
    await prefs.remove(_recentSearchesKey);
    await prefs.remove(_hasGivenConsentKey);
    await prefs.remove(_consentDataKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_hasSelectedLanguageKey);
    await prefs.remove(_loginBlockTimeKey);
    await prefs.remove(_signupBlockTimeKey);
    await prefs.remove(_isSignupUser);
  }
}
