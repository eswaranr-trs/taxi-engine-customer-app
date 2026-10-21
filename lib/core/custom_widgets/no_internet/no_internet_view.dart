import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';

class NoInternetView extends StatelessWidget {
  const NoInternetView({super.key});

  Future<void> _retry(ConnectivityService service) async {
    final hasInternet = await service.hasInternet();

    if (!hasInternet) {
      service.isConnected.value = false;
      return;
    }

    service.isConnected.value = true;

    final serverHealthy = await service.serverHealthy();

    if (serverHealthy) {
      service.reportServerUp();

      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().checkRequirements(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) return const SizedBox.shrink();
    final service = Get.find<ConnectivityService>();
    return Obx(() {
      final bool offline = !service.isConnected.value;
      final bool serverDown = service.isServerDown.value;
      if (!offline && !serverDown) return const SizedBox.shrink();

      final bool showOffline = offline;
      final String title = showOffline ? 'No Internet Connection' : 'Server Temporarily Unavailable';
      final String message = showOffline
          ? 'Please check your internet connection and try again. We will automatically reconnect you when internet is restored.'
          : "We're updating our service and it will be back shortly. Your booking is safe.";

      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                showOffline
                    ? Image.asset('assets/images/no_internet.png', height: 250, width: 300)
                    : Image.asset('assets/images/server_down.png', height: 250, width: 300),
                CustomText(
                  text: title,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                  textAlign: TextAlign.center,
                ),
                10.height,
                CustomText(
                  text: message,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: AppColors.grey500,
                  textAlign: TextAlign.center,
                ),
                48.height,
                CustomButton(
                  onPressed: () => _retry(service),
                  text: 'Retry',
                  gradient: AppColors.gradientButton,
                  textColor: AppColors.white,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
