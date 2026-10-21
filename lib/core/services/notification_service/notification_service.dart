import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.stashTripEvent(message.data);
}

@pragma('vm:entry-point')
void _onLocalNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  try {
    NotificationService.handleTripEventTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
  } catch (_) {}
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String pendingTripEventKey = 'pending_trip_event';

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  static Future<void> stashTripEvent(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingTripEventKey, jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> handleTripEventTap(Map<String, dynamic> data) async {
    await stashTripEvent(data);
    if (!Get.isRegistered<TripStateService>()) return;
    await Get.find<TripStateService>().handleAppResumed(force: true);
  }

  static Future<void> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
      print("Permission: ${settings.authorizationStatus}");

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await FirebaseMessaging.instance.getToken();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/logo_icon'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onLocalNotificationTap,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("MESSAGE RECEIVED");
        debugPrint("Title: ${message.notification?.title}");
        debugPrint("Body: ${message.notification?.body}");

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: 'logo_icon',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            payload: message.data.isEmpty ? null : jsonEncode(message.data),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        handleTripEventTap(message.data);
      });

      final RemoteMessage? launchMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (launchMessage != null) {
        await stashTripEvent(launchMessage.data);
      }

      print("FCM TOKEN: $token");
    } catch (e, stackTrace) {
      print("FCM ERROR: $e");
      print(stackTrace);
    }
  }
}
