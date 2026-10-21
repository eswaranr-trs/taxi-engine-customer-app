import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/app_widgets/app_widgets.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/secure_storage_service.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/socket_service.dart';
import 'package:orange_taxi_customer_app/data/repositories/profile_api/profile_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const CustomText(text: 'Privacy', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
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
                16.height,
                buildSettingsTile(
                  title: 'Manage devices',
                  icon: Icons.devices,
                  iconBgColor: AppColors.primary.withValues(alpha: 0.12),
                  iconColor: AppColors.primary,
                  onTap: () => Get.toNamed(AppRoutes.activeDevices),
                ),
                buildSettingsTile(
                  title: 'Delete my account',
                  icon: Icons.delete_outline,
                  iconColor: AppColors.red,
                  iconBgColor: AppColors.red.withValues(alpha: 0.12),
                  onTap: () {
                    _showConfirmDialog(
                      title: 'Delete my account',
                      content: 'This action is irreversible. All your data will be permanently deleted. Are you sure?',
                      confirmText: 'Delete',
                      confirmColor: AppColors.red,
                      onConfirm: () async {
                        try {
                          await ProfileRepository().deleteAccount();
                          SocketService().disconnect();
                          await LocalStorageService.clear();
                          await SecureStorageService.clear();
                          AppSnackbar.success('Account Deleted', 'Your account has been permanently deleted.');
                          await Get.offAllNamed(AppRoutes.login);
                        } catch (e) {
                          AppSnackbar.error('Error', e is ApiException ? e.message : 'Failed to delete account');
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    Color confirmColor = AppColors.primary,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(text: title, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
              const SizedBox(height: 12),
              CustomText(text: content, fontSize: 14, color: AppColors.grey600, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Get.back(),
                      child: CustomText(text: 'Cancel', color: AppColors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Get.back();
                        onConfirm();
                      },
                      child: CustomText(text: confirmText, color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
