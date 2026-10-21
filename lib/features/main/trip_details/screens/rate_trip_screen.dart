import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/config/routes/app_route.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/avatar_image/avatar_image.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_button/custom_button.dart';

class RateTripScreen extends StatefulWidget {
  const RateTripScreen({super.key});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  int _selectedRating = 0;
  bool _ratingMissing = false;
  final TextEditingController _commentController = TextEditingController();

  static const List<String> _ratingLabels = ['Very bad', 'Bad', 'Okay', 'Good', 'Excellent'];

  final Set<String> _selectedTags = {};

  List<String> get _tags {
    switch (_selectedRating) {
      case 1:
        return ['Poor Driving', 'Dirty Car', 'Rude Behavior', 'Late Arrival'];

      case 2:
        return ['Unsafe Driving', 'Unclean Car', 'Not Professional', 'Delayed Pickup'];

      case 3:
        return ['Average Service', 'Okay Driving', 'Could Improve', 'Neutral Experience'];

      case 4:
        return ['Punctual', 'Clean Car', 'Safe Driving', 'Friendly'];

      case 5:
        return ['Excellent Service', 'Very Friendly', 'Smooth Ride', 'Highly Professional'];

      default:
        return [];
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  final TripsRepository tripsRepository = TripsRepository();
  final TripStateService _tripStateService = Get.find<TripStateService>();
  final isLoading = false.obs;

  Future<void> rateTrip() async {
    if (isLoading.value) return;
    if (_selectedRating == 0) {
      setState(() => _ratingMissing = true);
      return;
    }
    isLoading.value = true;

    try {
      final String bookingId = _tripStateService.pendingRating?.bookingId?.isNotEmpty == true
          ? _tripStateService.pendingRating!.bookingId!
          : (_tripStateService.selectedBookingId.value.isNotEmpty
                ? _tripStateService.selectedBookingId.value
                : (_tripStateService.selectedTrip?.bookingId ?? _tripStateService.lastFinishedTrip?.bookingId ?? ''));

      if (bookingId.isEmpty) {
        AppSnackbar.error('Error', 'Booking ID is missing');
        isLoading.value = false;
        return;
      }

      final String userComment = _commentController.text.trim();
      final String tagsCsv = _selectedTags.join(', ');
      final String comment = [
        if (userComment.isNotEmpty) userComment,
        if (tagsCsv.isNotEmpty) tagsCsv,
      ].join(userComment.isNotEmpty && tagsCsv.isNotEmpty ? ' — ' : '');

      final Map<String, dynamic> body = {'booking_id': bookingId, 'rating': _selectedRating, 'comment': comment};

      final response = await tripsRepository.rateTrip(body);
      isLoading.value = false;
      if (response != null && response['success'] == true) {
        _tripStateService.clearPendingRating();
        Get.offAllNamed(AppRoutes.home);
        AppSnackbar.success('Success', response['message']?.toString() ?? 'Trip rated successfully');
      } else {
        AppSnackbar.error('Error', response?['message']?.toString() ?? 'Failed to rate trip');
      }
      return;
    } catch (e) {
      AppSnackbar.error('Error', e.toString());
    }
    isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final tripStateService = Get.find<TripStateService>();
    final activeTrip =
        tripStateService.pendingRating ?? tripStateService.selectedTrip ?? tripStateService.lastFinishedTrip;
    final String driverName = activeTrip?.driverName ?? 'Sample name';
    final String vehicleName = activeTrip?.vehicleType ?? activeTrip?.vehicleModel ?? 'Sample vehicle';
    final String plateNumber = activeTrip?.plateNumber ?? 'ABC-1234';
    final String destination = activeTrip?.destinationLocation ?? 'Sample Destination';
    final double? ratingVal = activeTrip?.driverRating;
    final String ratingText = (ratingVal ?? 0).toStringAsFixed(1);

    final String shortDest = _getShortAddress(destination);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _tripStateService.clearPendingRating();
          Get.offAllNamed(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          surfaceTintColor: AppColors.transparent,
          elevation: 0,
          leading: SizedBox.shrink(),
          title: const CustomText(
            text: 'Rate Your Trip',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkSlate,
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                _tripStateService.clearPendingRating();
                Get.offAllNamed(AppRoutes.home);
              },
              child: const CustomText(
                text: 'SKIP',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            8.width,
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarImage(size: 68, url: activeTrip?.driverImage),

                    16.width,

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  textAlign: TextAlign.left,
                                  text: driverName,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          6.height,
                          CustomText(text: "$vehicleName • $plateNumber", fontSize: 14, color: AppColors.grey650),
                          12.height,

                          Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 15, color: AppColors.primary),
                                  4.width,
                                  CustomText(
                                    text: ratingText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.normalText,
                                  ),
                                ],
                              ),
                              4.width,
                              CustomText(
                                text: "Rating",
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey650,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              32.height,

              CustomText(
                text: 'How was your ride to $shortDest?',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkSlate,
              ),
              16.height,

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final int starIndex = index + 1;
                  final bool isFilled = starIndex <= _selectedRating;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starIndex;
                        _ratingMissing = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: AnimatedScale(
                        scale: isFilled ? 1.12 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFilled ? AppColors.primary : (_ratingMissing ? AppColors.red : AppColors.grey300),
                          size: 44,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              12.height,
              CustomText(
                text: _ratingMissing
                    ? 'Please select a star rating'
                    : (_selectedRating == 0 ? 'Tap stars to rate' : _ratingLabels[_selectedRating - 1]),
                fontSize: 14,
                fontWeight: _selectedRating == 0 ? FontWeight.normal : FontWeight.bold,
                color: _ratingMissing ? AppColors.red : (_selectedRating == 0 ? AppColors.grey400 : AppColors.primary),
              ),
              24.height,

              Column(
                children: [
                  for (int i = 0; i < _tags.length; i += 2) ...[
                    if (i > 0) 10.height,
                    Row(
                      children: [
                        Expanded(child: _tagChip(_tags[i])),
                        10.width,
                        if (i + 1 < _tags.length) Expanded(child: _tagChip(_tags[i + 1])) else const Spacer(),
                      ],
                    ),
                  ],
                ],
              ),
              24.height,

              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tell us about your trip...',
                    hintStyle: TextStyle(color: AppColors.grey400, fontFamily: 'Poppins'),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: AppColors.darkSlate, fontSize: 14, fontFamily: 'Poppins'),
                ),
              ),
              32.height,

              CustomButton(
                text: 'Submit Feedback',
                onPressed: rateTrip,
                gradient: AppColors.gradientButton,
                textColor: AppColors.white,
              ),
              20.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagChip(String tag) {
    final bool isSelected = _selectedTags.contains(tag);
    return GestureDetector(
      onTap: () => _toggleTag(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber50 : AppColors.white,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey100, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomText(
          text: tag,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.grey600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _getShortAddress(String address) {
    if (address.isEmpty) return 'City';
    final parts = address.split(',');
    return parts.first.trim();
  }
}
