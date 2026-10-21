import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/themes/app_tokens.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/dashed_border/dashed_border_painter.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/controller/saved_address_controller.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/model/saved_address_model.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/widgets/address_form_bottom_sheet.dart';

class SavedAddressesScreen extends StatelessWidget {
  final SavedAddressesController controller = Get.find<SavedAddressesController>();

  SavedAddressesScreen({super.key});

  void _showAddressForm(BuildContext context, {var existingAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormBottomSheet(existingAddress: existingAddress),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        backgroundColor: AppColors.backgroundColor,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        title: const CustomText(
          text: "Saved Addresses",
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _loadingSkeleton();
        }
        return AppRefreshIndicator(
          onRefresh: () => controller.loadSavedAddresses(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList.list(
                children: [
                  const CustomText(
                    text: 'Drag to reorder, tap to edit',
                    fontSize: 12,
                    color: AppColors.slate500,
                    textAlign: TextAlign.left,
                  ),
                  16.height,
                  if (controller.addresses.isEmpty) _emptyCard() else _addressList(context),
                  12.height,
                  _addAddressCard(context),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _addressList(BuildContext context) {
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
        itemCount: controller.addresses.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }

          final item = controller.addresses.removeAt(oldIndex);
          controller.addresses.insert(newIndex, item);
        },
        proxyDecorator: (child, index, animation) => Material(
          color: AppColors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          shadowColor: AppColors.black.withValues(alpha: 0.15),
          child: child,
        ),
        itemBuilder: (context, index) =>
            _addressTile(context, index, controller.addresses[index], isLast: index == controller.addresses.length - 1),
      ),
    );
  }

  Widget _addressTile(BuildContext context, int index, AddressModel address, {required bool isLast}) {
    IconData icon = Icons.location_on_outlined;
    Color iconColor = AppColors.info;
    Color bgColor = AppColors.blue50;

    if (address.type.toLowerCase() == 'home') {
      icon = Icons.home_outlined;
      iconColor = AppColors.amber500;
      bgColor = AppColors.amber50;
    } else if (address.type.toLowerCase() == 'work') {
      icon = Icons.work_outline;
      iconColor = AppColors.info;
      bgColor = AppColors.blue50;
    }

    return Column(
      key: ValueKey(address.id.isNotEmpty ? address.id : 'slot_${address.type}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              12.width,
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddressForm(context, existingAddress: address),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        text: address.nickname,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      2.height,
                      CustomText(
                        text: address.fullAddress.isEmpty ? 'Add address' : address.fullAddress,
                        fontSize: 11,
                        color: address.fullAddress.isEmpty ? AppColors.grey400 : AppColors.slate500,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (address.type.toLowerCase() != 'home' && address.type.toLowerCase() != 'work') ...[
                GestureDetector(
                  onTap: () => controller.deleteAddress(address.id),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 17, color: AppColors.red),
                  ),
                ),
              ],
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

  Widget _addAddressCard(BuildContext context) {
    return InkWell(
      onTap: () => _showAddressForm(context),
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
                      text: 'Add a new address',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                      textAlign: TextAlign.left,
                    ),
                    CustomText(
                      text: 'Save the places you travel to often',
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

  Widget _loadingSkeleton() {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 150, height: 12),
            16.height,
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey100),
                boxShadow: AppShadows.sm,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) Container(height: 1, color: AppColors.grey100),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                      child: Row(
                        children: [
                          const SkeletonBox(width: 30, height: 30, radius: 15),
                          12.width,
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 90, height: 11),
                                SizedBox(height: 6),
                                SkeletonBox(width: double.infinity, height: 10),
                              ],
                            ),
                          ),
                          12.width,
                          const SkeletonBox(width: 17, height: 17, radius: 4),
                          10.width,
                          const SkeletonBox(width: 18, height: 18, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            12.height,
            const SkeletonBox(width: double.infinity, height: 62, radius: 16),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 40, color: AppColors.grey300),
          12.height,
          const CustomText(
            text: 'No saved addresses yet',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.darkSlate,
          ),
          4.height,
          const CustomText(text: 'Add one below to book faster', fontSize: 11, color: AppColors.slate500),
        ],
      ),
    );
  }
}
