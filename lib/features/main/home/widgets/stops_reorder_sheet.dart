import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dashed_border/dashed_border_painter.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';

class StopsReorderSheet extends StatelessWidget {
  const StopsReorderSheet({super.key});

  static const int _maxStops = 3;

  static Future<void> show() {
    return Get.bottomSheet(const StopsReorderSheet(), isScrollControlled: true, backgroundColor: AppColors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: AppRadius.sheetTop),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          10.height,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(10)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: CustomText(
                        text: 'Manage Stops',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                4.height,
                const CustomText(
                  text: 'Drag to reorder, tap to edit',
                  fontSize: 12,
                  color: AppColors.slate500,
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

          16.height,

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    if (controller.stops.isEmpty) return const SizedBox.shrink();
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey100),
                        boxShadow: AppShadows.sm,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        buildDefaultDragHandles: false,
                        itemCount: controller.stops.length,
                        onReorder: (oldIndex, newIndex) =>
                            controller.moveStop(oldIndex, newIndex > oldIndex ? newIndex - 1 : newIndex),
                        proxyDecorator: (child, index, animation) => Material(
                          color: AppColors.white,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          shadowColor: AppColors.black.withValues(alpha: 0.15),
                          child: child,
                        ),
                        itemBuilder: (context, index) => _stopTile(
                          controller,
                          index,
                          controller.stops[index],
                          isLast: index == controller.stops.length - 1,
                        ),
                      ),
                    );
                  }),

                  Obx(() {
                    if (controller.stops.length >= _maxStops) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: controller.stops.isEmpty ? 0 : 12),
                      child: _addStopCard(controller),
                    );
                  }),
                ],
              ),
            ),
          ),

          16.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomButton(
              text: 'Done',
              gradient: AppColors.gradientButton,
              textColor: AppColors.white,
              onPressed: Get.back,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addStop(HomeController controller) async {
    final result = await Get.toNamed(AppRoutes.locationSearch, arguments: 'Stop');
    if (result is! Map) return;

    final double? lat = (result['lat'] as num?)?.toDouble();
    final double? lng = (result['lng'] as num?)?.toDouble();
    if (lat != null && lng != null && controller.rejectIfDuplicate(LatLng(lat, lng))) return;

    controller.stops.add(Map<String, dynamic>.from(result));
  }

  Future<void> _editStop(HomeController controller, int index) async {
    final result = await Get.toNamed(AppRoutes.locationSearch, arguments: 'Stop');
    if (result is! Map || index >= controller.stops.length) return;

    final double? lat = (result['lat'] as num?)?.toDouble();
    final double? lng = (result['lng'] as num?)?.toDouble();
    if (lat != null && lng != null && controller.rejectIfDuplicate(LatLng(lat, lng), skipStop: index)) return;

    controller.stops[index] = Map<String, dynamic>.from(result);
    controller.stops.refresh();
  }

  Widget _addStopCard(HomeController controller) {
    return InkWell(
      onTap: () => _addStop(controller),
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: const DashedBorderPainter(color: AppColors.primary, radius: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, size: 18, color: AppColors.white),
              ),
              12.width,
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: 'Add another stop',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                      textAlign: TextAlign.left,
                    ),
                    CustomText(
                      text: 'Plan multiple pickups along the way',
                      fontSize: 11,
                      color: AppColors.slate500,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stopTile(HomeController controller, int index, Map<String, dynamic> stop, {required bool isLast}) {
    final String title = (stop['mainText'] ?? '').toString();
    return Column(
      key: ValueKey('stop_$index'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
          child: Row(
            children: [
              _indexBadge(index),
              12.width,
              Expanded(
                child: GestureDetector(
                  onTap: () => _editStop(controller, index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        text: title.isEmpty ? 'Stop ${index + 1}' : title,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => controller.stops.removeAt(index),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 17, color: AppColors.red),
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.drag_indicator, size: 18, color: AppColors.grey300),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: AppColors.grey100),
      ],
    );
  }

  Widget _indexBadge(int index) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
      child: Center(
        child: CustomText(text: '${index + 1}', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amber700),
      ),
    );
  }
}
