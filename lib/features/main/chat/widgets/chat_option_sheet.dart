import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/chat/services/chat_unread_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/badge/unread_badge.dart';

class ChatOptionSheet extends StatefulWidget {
  const ChatOptionSheet({super.key});

  static Future<void> show() async {
    final unread = Get.find<ChatUnreadService>();
    await unread.refreshCounts();

    final bool driverOnly = unread.fromDriver.value > 0 && unread.fromAdmin.value == 0;
    final bool adminOnly = unread.fromAdmin.value > 0 && unread.fromDriver.value == 0;
    if (driverOnly || adminOnly) {
      await Get.toNamed(AppRoutes.chat, arguments: {'type': driverOnly ? 'driver' : 'support'});
      return;
    }

    await Get.bottomSheet(const ChatOptionSheet(), isScrollControlled: true, backgroundColor: AppColors.transparent);
  }

  @override
  State<ChatOptionSheet> createState() => _ChatOptionSheetState();
}

class _ChatOptionSheetState extends State<ChatOptionSheet> {
  String selected = 'driver';
  final ChatUnreadService _unread = Get.find<ChatUnreadService>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const CustomText(text: 'Chat', fontSize: 18, fontWeight: FontWeight.bold),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.close, size: 22, color: AppColors.grey500),
              ),
            ],
          ),
          16.height,
          const CustomText(text: 'Select a support option', fontSize: 13, color: AppColors.grey500),
          16.height,
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(30)),
            child: Obx(
              () => Row(
                children: [
                  _ToggleOption(
                    label: 'Driver',
                    unread: _unread.fromDriver.value,
                    isActive: selected == 'driver',
                    onTap: () => setState(() => selected = 'driver'),
                  ),
                  _ToggleOption(
                    label: 'Support',
                    unread: _unread.fromAdmin.value,
                    isActive: selected == 'support',
                    onTap: () => setState(() => selected = 'support'),
                  ),
                ],
              ),
            ),
          ),
          24.height,
          GestureDetector(
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.chat, arguments: {'type': selected});
            },
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(gradient: AppColors.gradientButton, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: CustomText(text: 'Continue', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final int unread;
  final VoidCallback onTap;

  const _ToggleOption({required this.label, required this.isActive, required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.gradientButton : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                text: label,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.grey500,
              ),
              if (unread > 0) ...[
                6.width,
                UnreadBadge(count: unread, borderColor: isActive ? AppColors.white : AppColors.grey100),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
