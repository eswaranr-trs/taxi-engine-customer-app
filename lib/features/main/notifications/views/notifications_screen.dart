import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/notifications/controllers/notifications_controller.dart';
import 'package:orange_taxi_customer_app/features/main/notifications/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController controller = Get.isRegistered<NotificationsController>()
      ? Get.find<NotificationsController>()
      : Get.put(NotificationsController());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => controller.fetch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.transparent,
        title: const CustomText(
          text: 'Notifications',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        centerTitle: true,
        leading: InkWell(
          onTap: () => Get.back(),
          child: Icon(Icons.arrow_back, color: AppColors.black),
        ),
        actions: [
          Obx(() {
            controller.items.length;
            final bool hasUnread = controller.unreadCount.value > 0 || controller.items.any((n) => !n.isRead);
            return hasUnread
                ? GestureDetector(
                    onTap: controller.markAllRead,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all_rounded, size: 13, color: AppColors.primary),
                          SizedBox(width: 5),
                          CustomText(
                            text: 'Mark all as read',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
          12.width,
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) return _loading();
        if (controller.error.value != null && controller.items.isEmpty) {
          return _empty(Icons.error_outline, controller.error.value!);
        }
        if (controller.items.isEmpty) {
          return Center(child: _empty(Icons.notifications_none_rounded, 'No notifications yet'));
        }

        return AppRefreshIndicator(
          onRefresh: controller.fetch,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => 12.height,
                itemBuilder: (_, i) {
                  final n = controller.items[i];
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => controller.delete(n),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_outline, color: AppColors.white),
                    ),
                    child: _tile(n),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _tile(NotificationModel n) {
    final IconData icon = n.notificationType.toLowerCase().contains('trip')
        ? Icons.local_taxi
        : n.notificationType.toLowerCase().contains('payment')
        ? Icons.account_balance_wallet_outlined
        : n.notificationType.toLowerCase().contains('offer') || n.notificationType.toLowerCase().contains('promo')
        ? Icons.local_offer_outlined
        : Icons.notifications_none_rounded;

    final bool unread = !n.isRead;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: unread ? () => controller.markRead(n) : null,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: unread ? AppColors.primary.withValues(alpha: 0.06) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.grey100),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: unread ? AppColors.primary : AppColors.transparent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: unread ? 0.14 : 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 20, color: AppColors.primary),
                        ),
                        12.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                    text: n.title,
                                    fontSize: 14,
                                    fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                                    color: unread ? AppColors.darkSlate : AppColors.grey700,
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (unread) ...[
                                    6.width,
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              4.height,
                              CustomText(
                                text: n.body,
                                fontSize: 13,
                                color: unread ? AppColors.slate500 : AppColors.grey500,
                                textAlign: TextAlign.left,
                                maxLines: 3,
                              ),
                              6.height,
                              CustomText(text: _ago(n.createdAt), fontSize: 11, color: AppColors.grey400),
                              // if (unread) ...[
                              //   10.width,
                              //   GestureDetector(
                              //     onTap: () => controller.markRead(n),
                              //     child: const CustomText(
                              //       text: 'Mark as read',
                              //       fontSize: 11,
                              //       fontWeight: FontWeight.w600,
                              //       color: AppColors.primary,
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                        ),

                        GestureDetector(
                          onTap: () => controller.delete(n),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.delete_outline, size: 20, color: AppColors.grey400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t.toLocal());
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    final lt = t.toLocal();
    return '${lt.day}/${lt.month}/${lt.year}';
  }

  Widget _loading() {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, _) => 12.height,
        itemBuilder: (_, _) => Row(
          children: [
            SkeletonBox(width: 40, height: 40, radius: 20),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 12),
                  8.height,
                  SkeletonBox(width: 180, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(IconData icon, String message) {
    final controller = Get.find<NotificationsController>();
    return AppRefreshIndicator(
      onRefresh: controller.fetch,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: AppColors.grey300),
                16.height,
                CustomText(text: message, fontSize: 15, color: AppColors.grey400, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
