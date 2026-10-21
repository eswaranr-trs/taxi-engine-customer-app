import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/refresh_indicator/app_refresh_indicator.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/shimmer/shimmer.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/active_trips_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class ActiveTripsScreen extends GetView<ActiveTripsController> {
  const ActiveTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const CustomText(text: 'Active Trips', fontSize: 18, fontWeight: FontWeight.w600),
        centerTitle: true,
        backgroundColor: AppColors.grey100,
        surfaceTintColor: AppColors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Shimmer(child: Column(children: List.generate(5, (_) => const TripCardSkeleton())));
        }

        final trips = controller.displayTrips;

        if (trips.isEmpty) {
          return AppRefreshIndicator(
            onRefresh: () async {
              await controller.fetchActiveTrips();
            },
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CustomText(text: 'No active trips found', fontSize: 16, color: AppColors.grey400),
                ),
              ),
            ],
          );
        }

        return AppRefreshIndicator(
          onRefresh: () async {
            await controller.fetchActiveTrips();
          },
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: trips.length,
                separatorBuilder: (_, _) => 12.height,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  final status = trip['status']?.toString() ?? '';
                  final paymentStatus = trip['paymentStatus']?.toString() ?? '';
                  final advStatus = (trip['advancePaymentStatus'] ?? '').toString().toLowerCase();
                  final advancePaid = advStatus == 'paid' || advStatus == 'success' || advStatus == 'completed';
                  final isUnpaid =
                      paymentStatus.isNotEmpty && !TripStateService.isPaidStatus(paymentStatus) && !advancePaid;

                  return GestureDetector(
                    onTap: () {
                      if (trip['_localPending'] == true) {
                        final ts = Get.find<TripStateService>();
                        ts.entrySource.value = 'ongoing';
                        ts.switchTrip(trip['_id']);
                        ts.resumeRideFlow();
                      } else {
                        Get.find<HomeController>().resumeTripFromData(trip);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_taxi, color: AppColors.primary),
                              ),

                              12.width,

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: trip['bookingId'] ?? trip['_id'] ?? '',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      textAlign: TextAlign.left,
                                    ),

                                    4.height,

                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withValues(alpha: .15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: CustomText(
                                            text: status,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                        if (isUnpaid) ...[
                                          6.width,
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.red.withValues(alpha: .15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: CustomText(
                                              text: 'Unpaid',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.red,
                                            ),
                                          ),
                                        ] else if (advancePaid) ...[
                                          6.width,
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.green.withValues(alpha: .15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: CustomText(
                                              text: 'Advance Paid',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.green,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          16.height,

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.my_location, color: Colors.green, size: 18),

                              8.width,

                              Expanded(
                                child: CustomText(
                                  text: trip['pickupAddress'] ?? 'Pickup Location',
                                  fontSize: 12,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),

                          10.height,

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),

                              8.width,

                              Expanded(
                                child: CustomText(
                                  text: trip['dropoffAddress'] ?? 'Destination',
                                  fontSize: 12,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booking confirmed':
        return AppColors.orange;

      case 'booking accepted':
        return AppColors.info;

      case 'pickup arrived':
        return AppColors.primary;

      case 'started':
        return AppColors.green;

      case 'completed':
        return AppColors.green;

      default:
        return AppColors.grey;
    }
  }
}
