import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

Widget buildSettingsTile({
  required IconData icon,
  required Color iconColor,
  required Color iconBgColor,
  required String title,
  String? subtitle,
  Color titleColor = AppColors.charcoal,
  bool showChevron = true,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: Row(
        children: [
          // Circular Colored Icon container
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          16.width,

          // Text section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: title,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  textAlign: TextAlign.left,
                ),
                if (subtitle != null) ...[
                  4.height,
                  CustomText(text: subtitle, fontSize: 12, color: AppColors.grey400, textAlign: TextAlign.left),
                ],
              ],
            ),
          ),

          // Trailing Chevron
          if (showChevron) Icon(Icons.chevron_right, color: AppColors.grey300, size: 20),
        ],
      ),
    ),
  );
}
