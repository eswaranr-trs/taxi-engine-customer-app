import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/config/constants/app_endpoints.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/api_service.dart';

class SupportService {
  static Future<Map<String, String>> getCompanyInfo() async {
    final info = {'name': 'Support', 'email': '', 'phone': AppConstants.supportPhone};
    try {
      final res = await Get.find<ApiService>().get(AppEndpoints.companyProfile, requiresToken: true);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map?;
        final p = d?['phone']?.toString();
        final e = d?['email']?.toString();
        final n = d?['companyName']?.toString() ?? d?['name']?.toString();
        if (p != null && p.trim().isNotEmpty) info['phone'] = p.trim();
        if (e != null && e.trim().isNotEmpty) info['email'] = e.trim();
        if (n != null && n.trim().isNotEmpty) info['name'] = n.trim();
      }
    } catch (_) {}
    return info;
  }

  static Future<void> contactSupport() async {
    final info = await getCompanyInfo();
    await _launch('tel:${info['phone']}');
  }

  static Future<void> showSupportOptions() async {
    final info = await getCompanyInfo();
    final String phone = info['phone'] ?? '';
    final String email = info['email'] ?? '';

    await Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            20.height,
            const CustomText(
              text: 'Help & Support',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
            4.height,
            const CustomText(
              text: 'We\'re here 24/7 — reach us any time.',
              fontSize: 13,
              color: AppColors.grey500,
              textAlign: TextAlign.left,
            ),
            20.height,
            if (phone.isNotEmpty)
              _tile(
                icon: Icons.call_outlined,
                title: 'Call us',
                subtitle: phone,
                onTap: () {
                  Get.back();
                  _launch('tel:$phone');
                },
              ),
            if (email.isNotEmpty) ...[
              12.height,
              _tile(
                icon: Icons.mail_outline_rounded,
                title: 'Email us',
                subtitle: email,
                onTap: () {
                  Get.back();
                  _launch('mailto:$email?subject=${Uri.encodeComponent('Orange Taxi — Support')}');
                },
              ),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );
  }

  static Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: title, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
                  2.height,
                  CustomText(
                    text: subtitle,
                    fontSize: 12,
                    color: AppColors.grey500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }

  static Future<void> _launch(String uri) async {
    try {
      if (!await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication)) {
        AppSnackbar.error('Support', 'Could not open the app for this action');
      }
    } catch (_) {
      AppSnackbar.error('Support', 'Could not open the app for this action');
    }
  }
}
