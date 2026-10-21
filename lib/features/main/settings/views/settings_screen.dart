import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/app_widgets/app_widgets.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const CustomText(text: 'Settings', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                // 16.height,
                // buildSettingsTile(
                //   title: 'Language Selection',
                //   icon: Icons.language,
                //   iconBgColor: AppColors.blue.withValues(alpha: 0.12),
                //   iconColor: AppColors.blue,
                //   onTap: () {
                //     Get.toNamed(AppRoutes.language, arguments: {'fromSettings': true});
                //   },
                // ),
                buildSettingsTile(
                  title: 'Manage Notifications',
                  icon: Icons.notifications_none_rounded,
                  iconBgColor: AppColors.blue.withValues(alpha: 0.12),

                  iconColor: AppColors.blue,
                  onTap: () {
                    Get.toNamed(AppRoutes.notificationSettings);
                  },
                ),
                Divider(color: AppColors.grey300, thickness: 0.3, indent: 16, endIndent: 16),
                buildSettingsTile(
                  title: 'Privacy',
                  icon: Icons.privacy_tip_outlined,
                  iconBgColor: AppColors.green.withValues(alpha: 0.12),
                  iconColor: AppColors.green,
                  onTap: () {
                    Get.toNamed(AppRoutes.privacySettings);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
