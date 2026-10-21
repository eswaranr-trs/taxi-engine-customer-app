import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // static const String baseUrl = "http://192.168.0.141:9048";
  // static const String baseUrl = "https://demo.api.orangetaxi.fleto.in";
  static const String baseUrl = "https://api.orangetaxi.fleto.in";
  static const String rupeesSymbol = "₹";
  static const String supportPhone = "";

  static final String googleMapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String googleServerClientId = "890458727287-18f91jr668vcon5s608kq6cqmbladph2.apps.googleusercontent.com";

  static const String appVersion = "1.0.0";

  static String get platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return Platform.operatingSystem;
  }

  static Future<String> getDeviceModel() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        return '${a.manufacturer} ${a.model}'.trim();
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        return i.utsname.machine;
      }
    } catch (_) {}
    return '';
  }

  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? '';
    } else if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      return webInfo.userAgent?.toString() ?? 'web-device';
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.machineId ?? '';
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      return macInfo.systemGUID ?? '';
    }

    return '';
  }
}
