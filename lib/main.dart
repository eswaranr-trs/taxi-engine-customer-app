import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/no_internet/no_internet_view.dart';
import 'package:orange_taxi_customer_app/initial_binding.dart';
import 'package:orange_taxi_customer_app/config/translations/languages.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';

import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:orange_taxi_customer_app/core/services/notification_service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
  } catch (e, stackTrace) {
    debugPrint("Firebase/FCM ERROR: $e $stackTrace");
  }

  await dotenv.load(fileName: ".env");
  await Languages.init();
  String? langCode = await LocalStorageService.getLanguage();
  Locale initialLocale;

  final Map<String, Locale> supportedLocales = {
    'en': const Locale('en', 'US'),
    'hi': const Locale('hi', 'IN'),
    'ta': const Locale('ta', 'IN'),
    'te': const Locale('te', 'IN'),
    'kn': const Locale('kn', 'IN'),
    'bn': const Locale('bn', 'IN'),
    'mr': const Locale('mr', 'IN'),
    'gu': const Locale('gu', 'IN'),
    'ar': const Locale('ar', 'AE'),
  };

  if (langCode != null && supportedLocales.containsKey(langCode)) {
    initialLocale = supportedLocales[langCode]!;
  } else {
    Locale deviceLocale = Get.deviceLocale ?? const Locale('en', 'US');

    if (supportedLocales.containsKey(deviceLocale.languageCode)) {
      initialLocale = supportedLocales[deviceLocale.languageCode]!;
    } else {
      initialLocale = const Locale('en', 'US');
    }
  }

  runApp(MyApp(initialLocale: initialLocale));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orange Taxi',
      translations: Languages(),
      locale: initialLocale,
      fallbackLocale: const Locale('en_US', 'US'),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      routingCallback: (routing) {
        if (routing?.current == AppRoutes.home && Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().reconcileActiveTrips();
        }
      },
      initialBinding: InitialBinding(),
      builder: (context, child) {
        return Stack(children: [?child, const NoInternetView()]);
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.grey50,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.grey50, elevation: 0),
      ),
    );
  }
}
