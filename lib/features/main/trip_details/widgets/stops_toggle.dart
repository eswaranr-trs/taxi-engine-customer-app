import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class StopsToggle extends StatelessWidget {
  final EdgeInsets padding;

  const StopsToggle({super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final ts = Get.find<TripStateService>();
    return Obx(() {
      final stops = ts.lastBookingStops;
      if (stops.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => ts.showTripStops.toggle(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ts.showTripStops.value ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  4.width,
                  CustomText(
                    text: '${stops.length} ${stops.length > 1 ? 'stops' : 'stop'}',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (ts.showTripStops.value)
              ...stops.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.trip_origin, size: 12, color: AppColors.grey400),
                      8.width,
                      Expanded(
                        child: CustomText(
                          text:
                              (e.value['mainText'] ??
                                      e.value['address'] ??
                                      e.value['secondaryText'] ??
                                      'Stop ${e.key + 1}')
                                  .toString(),
                          fontSize: 12,
                          color: AppColors.slate500,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
