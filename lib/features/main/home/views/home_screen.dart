import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_navigation_bar/custom_navigation_bar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/trip_type_controller.dart';
import 'package:orange_taxi_customer_app/features/main/offers/views/offers_screen.dart';
import '../../../../core/custom_widgets/custom_text/custom_text.dart';
import '../controllers/home_controller.dart';
import '../../my_trips/views/my_trips_screen.dart';
import 'package:orange_taxi_customer_app/features/main/profile/views/profile_screen.dart';

import 'home_content.dart';
import 'location_disabled_view.dart';

class HomeScreen extends GetView<HomeController> {
  final String? pathName;
  final String? path;

  HomeScreen({super.key, this.path, this.pathName});

  final tripController = Get.find<TripController>();
  final activeTripsController = Get.find<ActiveTripsController>();

  Widget _ongoingTripPill(BuildContext context) {
    return Obx(() {
      final bool show =
          activeTripsController.displayTrips.isNotEmpty &&
          controller.isLocationServiceEnabled.value &&
          controller.hasLocationPermission.value &&
          !controller.isInitialLoading.value &&
          !controller.isMapSelectionMode.value &&
          controller.currentTab.value == 0;
      if (!show) return const SizedBox.shrink();

      final bool many = activeTripsController.displayTrips.length > 1;
      return GestureDetector(
        onTap: () => controller.handleTripDetailsTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.gradientButton,
            borderRadius: AppRadius.rLg,
            boxShadow: AppShadows.lg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
              ),
              10.width,
              CustomText(
                text: many ? 'Ongoing Trips' : 'Ongoing Trip',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.grey500,
              ),
              2.width,
              const Icon(Icons.keyboard_arrow_right, color: AppColors.grey500, size: 20),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.currentTab.value != 0) {
          controller.changeTab(0);
        } else if (controller.shouldExitOnBack()) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 8.0), child: _ongoingTripPill(context)),
        backgroundColor: AppColors.backgroundColor,

        body: Obx(() {
          if (!controller.isLocationServiceEnabled.value || !controller.hasLocationPermission.value) {
            return const LocationDisabledView();
          }

          final int tab = controller.currentTab.value;
          return IndexedStack(
            index: tab.clamp(0, 3),
            children: [
              const HomeContent(),
              const MyTripsScreen(),
              const OffersScreen(showBack: false),
              const ProfileScreen(),
            ],
          );
        }),
        bottomNavigationBar: Obx(() {
          final shouldHide =
              !controller.isLocationServiceEnabled.value ||
              !controller.hasLocationPermission.value ||
              controller.isMapSelectionMode.value;

          if (shouldHide) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              height: 52,
              child: CustomNavigationBar(currentIndex: controller.currentTab.value, onTap: controller.changeTab),
            ),
          );
        }),
      ),
    );
  }
}
