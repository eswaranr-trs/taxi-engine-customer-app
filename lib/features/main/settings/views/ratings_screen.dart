import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/settings/controllers/ratings_controller.dart';
import 'package:orange_taxi_customer_app/features/main/settings/models/rating_model.dart';

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<RatingsController>()
        ? Get.find<RatingsController>()
        : Get.put(RatingsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.transparent,
        title: const CustomText(text: 'My Ratings', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) return _loading();
        if (controller.error.value != null && controller.items.isEmpty) {
          return Center(child: _empty(Icons.error_outline, controller.error.value!));
        }
        if (controller.items.isEmpty) {
          return Center(child: _empty(Icons.star_border_rounded, 'No ratings yet'));
        }

        return AppRefreshIndicator(
          onRefresh: controller.fetch,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.list(
                children: [
                  _summaryCard(controller),
                  20.height,
                  const CustomText(
                    text: 'Reviews',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.left,
                  ),
                  12.height,
                  ...controller.items.map(
                    (r) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _reviewCard(r)),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _summaryCard(RatingsController c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: c.average.toStringAsFixed(1),
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
              _starRow(c.average.round(), size: 16),
              6.height,
              CustomText(text: '${c.total} rating${c.total == 1 ? '' : 's'}', fontSize: 12, color: AppColors.grey500),
            ],
          ),
          20.width,
          Container(width: 1, height: 90, color: AppColors.grey200),
          16.width,
          Expanded(child: Column(children: [for (int s = 5; s >= 1; s--) _breakdownBar(s, c.countFor(s), c.total)])),
        ],
      ),
    );
  }

  Widget _breakdownBar(int star, int count, int total) {
    final double pct = total == 0 ? 0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          CustomText(text: '$star', fontSize: 12, color: AppColors.grey500),
          4.width,
          const Icon(Icons.star_rounded, size: 12, color: AppColors.amber400),
          8.width,
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.amber400),
              ),
            ),
          ),
          8.width,
          SizedBox(
            width: 22,
            child: CustomText(text: '$count', fontSize: 12, color: AppColors.grey500, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(RatingModel r) {
    final String name = r.driverName.isNotEmpty ? r.driverName : 'Driver';
    final String initial = name.substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: CustomText(text: initial, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: name,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    3.height,
                    _starRow(r.rating, size: 13),
                    if (r.review.isNotEmpty) ...[
                      12.height,
                      CustomText(text: r.review, fontSize: 13, color: AppColors.slate500, textAlign: TextAlign.left),
                    ] else ...[
                      12.height,
                      CustomText(
                        text: 'No Comments',
                        fontSize: 13,
                        color: AppColors.slate500,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ],
                ),
              ),
              if (r.createdAt != null) CustomText(text: _ago(r.createdAt), fontSize: 11, color: AppColors.grey400),
            ],
          ),

          // if (r.serviceType.isNotEmpty) ...[
          //   10.height,
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //     decoration: BoxDecoration(
          //       color: AppColors.grey100,
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     child: CustomText(
          //       text: _titleCase(r.serviceType),
          //       fontSize: 11,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.grey700,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _starRow(int filled, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) =>
            Icon(i < filled ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.amber400),
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

    return DateFormat('d MMM yyyy').format(t.toLocal());
  }

  Widget _loading() {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SkeletonBox(width: double.infinity, height: 130, radius: 20),
          20.height,
          for (int i = 0; i < 4; i++) ...[SkeletonBox(width: double.infinity, height: 90, radius: 16), 12.height],
        ],
      ),
    );
  }

  Widget _empty(IconData icon, String message) {
    final controller = Get.find<RatingsController>();
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
