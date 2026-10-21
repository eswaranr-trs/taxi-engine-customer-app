import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/features/main/settings/controllers/notification_prefs_controller.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationPrefsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const CustomText(
          text: 'Notifications',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.available.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (controller.error.value != null && controller.available.isEmpty) {
          return _message(controller.error.value!, controller.fetch);
        }
        if (controller.available.isEmpty) {
          return _message('No notification types available', controller.fetch);
        }

        return AppRefreshIndicator(
          onRefresh: controller.fetch,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverList.list(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: CustomText(
                      text: 'Choose which notifications you want to receive.',
                      fontSize: 13,
                      color: AppColors.slate500,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        8.height,
                        for (int i = 0; i < controller.available.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                          _tile(controller, controller.available[i]),
                        ],
                        8.height,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _tile(NotificationPrefsController controller, String type) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(_iconFor(type), color: AppColors.primary, size: 20),
            ),
            16.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: type,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    textAlign: TextAlign.left,
                  ),
                  4.height,
                  CustomText(text: _subFor(type), fontSize: 12, color: AppColors.grey400, textAlign: TextAlign.left),
                ],
              ),
            ),
            CupertinoSwitch(
              value: controller.isOn(type),
              onChanged: (v) => controller.toggle(type, v),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.grey200,
              thumbColor: AppColors.backgroundBeige,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('trip')) return Icons.local_taxi_outlined;
    if (t.contains('offer') || t.contains('promo')) return Icons.local_offer_outlined;
    if (t.contains('account') || t.contains('security')) return Icons.shield_outlined;
    if (t.contains('sos') || t.contains('safety')) return Icons.emergency_outlined;
    if (t.contains('news')) return Icons.campaign_outlined;
    return Icons.notifications_none_rounded;
  }

  String _subFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('trip')) return 'Driver assigned, arrival, trip status';
    if (t.contains('offers')) return 'Discounts and deals';
    if (t.contains('promo')) return 'Promo codes';
    if (t.contains('account') || t.contains('security')) return 'Login, security and account activity';
    if (t.contains('sos')) return 'Emergency assistance';
    if (t.contains('safety')) return 'Safety alerts';
    if (t.contains('news')) return 'News and announcements';
    return 'Get $type notifications';
  }

  Widget _message(String message, Future<void> Function() onRetry) {
    return AppRefreshIndicator(
      onRefresh: onRetry,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.grey300),
                16.height,
                CustomText(text: message, fontSize: 14, color: AppColors.grey400, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
