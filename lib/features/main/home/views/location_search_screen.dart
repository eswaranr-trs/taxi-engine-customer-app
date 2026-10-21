import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/location_search_controller.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/model/saved_address_model.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';

class LocationSearchScreen extends GetView<LocationSearchController> {
  const LocationSearchScreen({super.key});

  static const Set<String> _mapPickerHidden = {'PickAddress', 'SavedAddress', 'Stop', 'EditPickup', 'EditDestination'};

  static String titleFor(String mode) {
    switch (mode) {
      case 'Pickup':
        return 'Select Pickup Location';
      case 'Destination':
        return 'Select Destination';
      case 'EditPickup':
        return 'Change Pickup Location';
      case 'EditDestination':
        return 'Change Destination';
      case 'Stop':
        return 'Select Stop';
      case 'SavedAddress':
        return 'Select Address';
      default:
        return 'Select Location';
    }
  }

  static String hintFor(String mode) {
    switch (mode) {
      case 'Pickup':
      case 'EditPickup':
        return 'Where should we pick you up?';
      case 'Destination':
      case 'EditDestination':
        return 'Where are you going?';
      case 'Stop':
        return 'Add a stop along the way';
      case 'SavedAddress':
        return 'Search the address to save';
      default:
        return 'Search for a location…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = (Get.arguments is String) ? Get.arguments as String : '';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: CustomText(text: titleFor(title), fontSize: 17, fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          _buildSearchBar(title),

          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.searchController,
            builder: (context, value, child) {
              if (value.text.isNotEmpty) return const SizedBox.shrink();
              return _buildQuickActions(title);
            },
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Shimmer(child: Column(children: List.generate(7, (_) => const ListRowSkeleton())));
              }
              if (controller.searchController.text.isEmpty) return _buildEmptyView();
              if (controller.suggestions.isEmpty) return _buildNoResultsState();

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: controller.suggestions.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.only(left: 66),
                  child: Divider(height: 1, color: AppColors.grey100),
                ),
                itemBuilder: (context, index) {
                  final suggestion = controller.suggestions[index];
                  final isSaved = suggestion['type'] == 'saved';
                  final label = suggestion['label'] as String?;
                  return _placeTile(
                    icon: isSaved ? (label == 'Home' ? Icons.home_rounded : Icons.work_rounded) : Icons.place_outlined,
                    iconColor: isSaved ? AppColors.primary : AppColors.grey500,
                    iconBg: isSaved ? AppColors.primary.withValues(alpha: 0.1) : AppColors.grey100,
                    title: isSaved ? label! : (suggestion['mainText'] ?? '').toString(),
                    subtitle: isSaved
                        ? (suggestion['mainText'] ?? '').toString()
                        : (suggestion['secondaryText'] ?? '').toString(),
                    onTap: () => controller.selectLocation(suggestion),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String mode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.search, color: AppColors.primary, size: 22),
            ),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                autofocus: true,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hintFor(mode),
                  hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.grey400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.searchController,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox(width: 8);
                return GestureDetector(
                  onTap: controller.searchController.clear,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.cancel, size: 18, color: AppColors.grey400),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(String title) {
    final bool showMapOption = !_mapPickerHidden.contains(title);
    final bool showCurrentOption =
        !controller.homeController.isPickupCurrent && !controller.homeController.isDestinationCurrent;

    if (!showCurrentOption && !showMapOption) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          if (showCurrentOption)
            Expanded(
              child: _actionCard(
                icon: Icons.my_location,
                color: AppColors.blue,
                label: 'Current Location',
                onTap: controller.useCurrentLocation,
              ),
            ),
          if (showMapOption) ...[
            if (showCurrentOption) 10.width,
            Expanded(
              child: _actionCard(
                icon: Icons.location_on,
                color: AppColors.primary,
                label: 'Set on Map',
                onTap: () {
                  controller.homeController.changeTab(0);
                  controller.homeController.polylines.clear();
                  controller.homeController.isMapSelectionMode.value = true;
                  Get.back();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            10.width,
            Expanded(
              child: CustomText(
                text: label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkSlate,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    2.height,
                    CustomText(
                      text: subtitle,
                      fontSize: 12,
                      color: AppColors.grey500,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: text,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.grey400,
            letterSpacing: 0.8,
            textAlign: TextAlign.left,
          ),
          ?action,
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Obx(() {
      final recents = controller.recentSearches;
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _buildSavedAddressesSection(),
          if (recents.isEmpty)
            _buildPopularLocations()
          else ...[
            _sectionHeader(
              'RECENT SEARCHES',
              action: GestureDetector(
                onTap: controller.clearRecent,
                child: const CustomText(
                  text: 'Clear all',
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...recents.map(
              (search) => _placeTile(
                icon: Icons.history,
                iconColor: AppColors.grey500,
                iconBg: AppColors.grey100,
                title: (search['mainText'] ?? '').toString(),
                subtitle: (search['secondaryText'] ?? '').toString(),
                onTap: () => controller.selectLocation(search),
                trailing: GestureDetector(
                  onTap: () => controller.removeRecent(search),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: AppColors.grey300, size: 17),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSavedAddressesSection() {
    if (Get.arguments == 'SavedAddress') return const SizedBox.shrink();

    return Obx(() {
      final saved = controller.savedSlots;
      if (saved.isEmpty) return const SizedBox.shrink();
      final primary = saved.where((a) => a.type == 'home' || a.type == 'work').toList();
      final others = saved
          .where(
            (a) => a.type != 'home' && a.type != 'work' && a.isPersisted && a.latitude != null && a.longitude != null,
          )
          .toList();
      final showAll = controller.showAllSaved.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SAVED ADDRESSES'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (primary.isNotEmpty) Expanded(child: _buildSavedChip(primary[0])),
                if (primary.length > 1) 10.width,
                if (primary.length > 1) Expanded(child: _buildSavedChip(primary[1])),
              ],
            ),
          ),
          if (showAll)
            ...others.map(
              (address) => _placeTile(
                icon: Icons.location_on,
                iconColor: AppColors.primary,
                iconBg: AppColors.primary.withValues(alpha: 0.1),
                title: address.nickname,
                subtitle: address.fullAddress,
                onTap: () => controller.selectLocation({
                  'placeId': address.id,
                  'mainText': address.fullAddress,
                  'secondaryText': '',
                  'lat': address.latitude,
                  'lng': address.longitude,
                  'type': 'saved',
                  'label': address.nickname,
                }),
              ),
            ),
          if (others.isNotEmpty && !showAll)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: GestureDetector(
                onTap: () => controller.showAllSaved.value = true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.expand_more, size: 18, color: AppColors.primary),
                    4.width,
                    CustomText(
                      text: '${others.length} more saved ${others.length == 1 ? 'address' : 'addresses'}',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          12.height,
          const Divider(height: 1, color: AppColors.grey100),
        ],
      );
    });
  }

  Widget _buildSavedChip(AddressModel address) {
    final IconData icon = address.type == 'home'
        ? Icons.home_rounded
        : address.type == 'work'
        ? Icons.work_rounded
        : Icons.location_on;
    final bool selectable = address.isPersisted && address.latitude != null && address.longitude != null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: selectable
          ? () => controller.selectLocation({
              'placeId': address.id,
              'mainText': address.fullAddress,
              'secondaryText': '',
              'lat': address.latitude,
              'lng': address.longitude,
              'type': 'saved',
              'label': address.nickname,
            })
          : () => Get.toNamed(AppRoutes.savedAddresses),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 17),
            ),
            10.width,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: address.nickname,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    maxLines: 1,
                    textAlign: TextAlign.left,
                  ),
                  CustomText(
                    text: selectable ? address.fullAddress : 'Tap to add',
                    fontSize: 11,
                    color: AppColors.grey500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            if (!selectable) const Icon(Icons.add, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularLocations() {
    return Obx(() {
      final nearby = controller.popularNearby;
      if (nearby.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SUGGESTIONS FOR YOU'),
          ...nearby.map(
            (place) => _placeTile(
              icon: Icons.place_outlined,
              iconColor: AppColors.blue,
              iconBg: AppColors.blue.withValues(alpha: 0.1),
              title: (place['mainText'] ?? '').toString(),
              subtitle: (place['secondaryText'] ?? '').toString(),
              onTap: () => controller.selectLocation(place),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNoResultsState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
          child: const Icon(Icons.search_off_rounded, size: 44, color: AppColors.grey300),
        ),
        16.height,
        const CustomText(
          text: 'No locations found',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.grey500,
        ),
        6.height,
        const CustomText(text: 'Try a different name or landmark', fontSize: 12.5, color: AppColors.grey400),
      ],
    );
  }
}
