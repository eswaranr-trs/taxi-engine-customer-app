import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';

class LocationDisabledView extends GetView<HomeController> {
  const LocationDisabledView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container(
                //   padding: const EdgeInsets.all(24),
                //   decoration: const BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
                //   child: const Icon(Icons.location_off_rounded, size: 80, color: AppColors.amber500),
                // ),
                // 40.height,
                Image.asset('assets/images/location_disabled.png', height: 250, width: 300),
                Obx(() {
                  bool isServiceDisabled = !controller.isLocationServiceEnabled.value;
                  String title = isServiceDisabled ? 'Location Disabled' : 'Permission Required';
                  String subtitle = isServiceDisabled
                      ? 'Enable location services to allow the app to fetch your current location.'
                      : 'Location permission is required to use this app. Please allow access in settings.';

                  return Column(
                    children: [
                      CustomText(text: title, fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
                      16.height,
                      CustomText(
                        text: subtitle,
                        textAlign: TextAlign.center,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.grey600,
                      ),
                    ],
                  );
                }),
                48.height,
                CustomButton(
                  onPressed: () async {
                    if (!controller.isLocationServiceEnabled.value) {
                      await Geolocator.openLocationSettings();
                    } else if (!controller.hasLocationPermission.value) {
                      await Geolocator.openAppSettings();
                    }
                  },
                  text: "Open Settings",
                  gradient: AppColors.gradientButton,
                  textColor: AppColors.white,
                ),
                // 16.height,
                // CustomButton(
                //   onPressed: () {
                //     controller.checkRequirements(true);
                //   },
                //   text: "Retry",
                //   textColor: AppColors.black,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
