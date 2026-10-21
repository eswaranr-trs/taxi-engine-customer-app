import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/data/repositories/auth_api/auth_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';

class ActiveDevicesController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final RxBool isLoading = true.obs;
  final RxBool isLoggingOut = false.obs;
  final RxnString error = RxnString();
  final RxList<Map<String, dynamic>> devices = <Map<String, dynamic>>[].obs;

  int get otherCount => devices.where((d) => d['isCurrentDevice'] != true).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final list = await _authRepo.getActiveDevices();
      list.sort((a, b) {
        if (a['isCurrentDevice'] == true) return -1;
        if (b['isCurrentDevice'] == true) return 1;
        return (b['lastActiveAt'] ?? '').toString().compareTo((a['lastActiveAt'] ?? '').toString());
      });
      devices.assignAll(list);
    } catch (e) {
      error.value = e is ApiException ? e.message : 'Failed to load devices';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logoutOthers() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    try {
      final res = await _authRepo.logoutOtherDevices();
      final count = res?['data']?['loggedOutCount'];
      final msg = (count is int && count > 0)
          ? 'Logged out $count other device${count == 1 ? '' : 's'}.'
          : (res?['message']?.toString() ?? 'No other devices were signed in.');
      AppSnackbar.success('Done', msg);
      await load();
    } catch (e) {
      AppSnackbar.error('Error', e is ApiException ? e.message : 'Failed to log out other devices');
    } finally {
      isLoggingOut.value = false;
    }
  }
}

class ActiveDevicesScreen extends StatelessWidget {
  const ActiveDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ActiveDevicesController());
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const CustomText(text: 'Devices', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return _skeleton();
        if (controller.error.value != null) return _errorState(controller);
        return _content(context, controller);
      }),
    );
  }

  Widget _content(BuildContext context, ActiveDevicesController c) {
    return AppRefreshIndicator(
      onRefresh: c.load,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.list(
            children: [
              const CustomText(
                text: 'These are the devices currently signed in to your account.',
                fontSize: 13,
                color: AppColors.grey600,
                textAlign: TextAlign.left,
              ),
              16.height,
              ...c.devices.map((d) => _deviceCard(d)),
              8.height,
              if (c.otherCount > 0)
                Obx(
                  () => CustomButton(
                    text: c.isLoggingOut.value ? 'Logging out...' : 'Log out from all other devices',
                    color: AppColors.grey,

                    textColor: AppColors.white, 
                    onPressed: c.isLoggingOut.value ? () {} : () => _confirmLogout(c),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deviceCard(Map<String, dynamic> d) {
    final bool current = d['isCurrentDevice'] == true;
    final String platform = (d['platform'] ?? '').toString();
    final String model = (d['deviceModel'] ?? d['deviceName'] ?? d['deviceId'] ?? 'Unknown device').toString();
    final String appVersion = (d['appVersion'] ?? '').toString();
    final String ip = (d['ipAddress'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: current ? AppColors.primary : AppColors.grey100, width: current ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_platformIcon(platform), color: AppColors.primary, size: 22),
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        text: model,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (current) ...[8.width, _currentBadge()],
                  ],
                ),
                4.height,
                CustomText(
                  text: [if (platform.isNotEmpty) platform, if (appVersion.isNotEmpty) 'v$appVersion'].join(' · '),
                  fontSize: 12,
                  color: AppColors.grey500,
                  textAlign: TextAlign.left,
                ),
                6.height,
                _metaRow(Icons.schedule, 'Last active ${_relative(d['lastActiveAt'])}'),
                if (ip.isNotEmpty) ...[4.height, _metaRow(Icons.public, ip)],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const CustomText(text: 'This device', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.green),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.grey400),
        6.width,
        Expanded(
          child: CustomText(
            text: text,
            fontSize: 12,
            color: AppColors.grey500,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('ios') || p.contains('iphone') || p.contains('ipad')) return Icons.phone_iphone;
    if (p.contains('android')) return Icons.phone_android;
    if (p.contains('web')) return Icons.language;
    return Icons.devices_other;
  }

  String _relative(dynamic iso) {
    final t = DateTime.tryParse((iso ?? '').toString());
    if (t == null) return 'recently';
    final diff = DateTime.now().difference(t.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.toLocal().day}/${t.toLocal().month}/${t.toLocal().year}';
  }

  void _confirmLogout(ActiveDevicesController c) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomText(
                text: 'Log out other devices',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              12.height,
              const CustomText(
                text: 'All other devices will be signed out. This device stays logged in.',
                fontSize: 14,
                color: AppColors.grey600,
                textAlign: TextAlign.center,
              ),
              24.height,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Get.back(),
                      child: const CustomText(text: 'Cancel', color: AppColors.black),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Get.back();
                        c.logoutOthers();
                      },
                      child: const CustomText(text: 'Log out', color: AppColors.white, fontWeight: FontWeight.bold),
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

  Widget _errorState(ActiveDevicesController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.grey400),
            16.height,
            CustomText(
              text: c.error.value ?? 'Something went wrong',
              fontSize: 14,
              color: AppColors.grey600,
              textAlign: TextAlign.center,
            ),
            20.height,
            SizedBox(
              width: 160,
              child: CustomButton(
                text: 'Retry',
                color: AppColors.primary,
                textColor: AppColors.white,
                onPressed: c.load,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              const Shimmer(child: SkeletonBox(width: 44, height: 44)),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Shimmer(child: SkeletonBox(width: 140, height: 14)),
                    SizedBox(height: 8),
                    Shimmer(child: SkeletonBox(width: 90, height: 12)),
                    SizedBox(height: 8),
                    Shimmer(child: SkeletonBox(width: 160, height: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
