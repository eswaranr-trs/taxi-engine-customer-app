import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';

class AvatarImage extends StatelessWidget {
  final String? url;
  final double size;
  final IconData icon;

  const AvatarImage({super.key, this.url, this.size = 60, this.icon = Icons.person});

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.grey50),
      child: Icon(icon, size: size * 0.55, color: AppColors.grey300),
    );

    final Widget loading = Shimmer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.grey200),
      ),
    );

    final String u = url?.trim() ?? '';
    if (u.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) => progress == null ? child : loading,
      ),
    );
  }
}
