import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class UnreadBadge extends StatelessWidget {
  final int count;
  final Color borderColor;

  const UnreadBadge({super.key, required this.count, this.borderColor = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: AppColors.redAccent,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: CustomText(
        text: count > 99 ? '99+' : '$count',
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
        textAlign: TextAlign.center,
      ),
    );
  }
}
