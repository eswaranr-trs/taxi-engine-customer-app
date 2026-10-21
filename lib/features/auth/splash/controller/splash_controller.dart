import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';

class SplashController extends GetxController {
  bool isNavigating = false;

  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  Future<void> _navigate() async {
    final Future<void> delay = Future.delayed(const Duration(seconds: 3));

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {}

    final bool loggedIn = await LocalStorageService.isLoggedIn();
    final bool hasGivenConsent = await LocalStorageService.hasGivenConsent();
    // final bool hasSelectedLanguage = await LocalStorageService.hasSelectedLanguage();
    final bool sessionExpired = await _isSessionExpired();
    final bool isNewUer = await LocalStorageService.isNewUser();

    // print('logged in is $loggedIn');
    // print('has given consent is $hasGivenConsent');
    // print('has selected language is $hasSelectedLanguage');
    // print('session expired is $sessionExpired');
    if (sessionExpired) {
      await SecureStorageService.clear();
      await LocalStorageService.setLoggedIn(false);
    }

    await delay;

    // if (!hasSelectedLanguage) {
    //   await Get.offNamed(AppRoutes.language, arguments: {'fromSettings': false});
    // } else

    if (loggedIn && !sessionExpired) {
      await LocalStorageService.saveLastActiveTime();
      final auth = Get.find<AuthRepository>();
      auth.listenFcmRefresh();
      auth.syncFcmToken();
      if (await LocalStorageService.isLoggedIn()) {
        await Get.offNamed(AppRoutes.home);
      } else {
        await Get.offAllNamed(AppRoutes.login);
      }
    } else if (!hasGivenConsent) {
      if (isNewUer) {
        await Get.offNamed(AppRoutes.welcome);
      } else {
        await Get.offNamed(AppRoutes.login);
      }
    } else {
      await Get.offNamed(AppRoutes.login);
    }
  }

  Future<bool> _isSessionExpired() async {
    final int? lastActive = await LocalStorageService.getLastActiveTime();

    if (lastActive == null) {
      return true;
    }

    final DateTime lastActiveTime = DateTime.fromMillisecondsSinceEpoch(lastActive);
    final Duration difference = DateTime.now().difference(lastActiveTime);
    return difference.inHours >= 24;
  }
}
