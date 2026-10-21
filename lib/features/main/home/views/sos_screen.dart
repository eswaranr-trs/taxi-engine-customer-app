import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_snackbar/custom_snackbar.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:orange_taxi_customer_app/data/repositories/trip_api/trips_repository.dart';
import 'package:orange_taxi_customer_app/data/repositories/exceptions/api_exceptions.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/home_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _holdController;

  final _tripsRepository = TripsRepository();
  final tripStateService = Get.find<TripStateService>();
  final homeController = Get.find<HomeController>();

  bool _preparing = false;
  bool _sending = false;
  bool _sent = false;
  bool _cancelling = false;

  Worker? _sosWorker;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _sosWorker = ever(tripStateService.sosActive, (bool active) {
      if (!active && mounted && _sent) {
        _holdController.reset();
        setState(() {
          _sent = false;
          _sending = false;
          _preparing = false;
        });
      }
    });

    _holdController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_sending && !_sent) {
          setState(() => _preparing = false);
          tripSos();
        }
      });
  }

  void _startHold() {
    if (_sending) return;
    setState(() {
      _sent = false;
      _preparing = true;
    });
    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
      setState(() => _preparing = false);
    }
  }

  Future<void> _cancelSos(String bookingId) async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      await _tripsRepository.cancelSOS(bookingId, reason: 'False alarm');

      if (!mounted) return;
      _holdController.reset();
      tripStateService.sosActive.value = false;
      setState(() {
        _sent = false;
        _sending = false;
        _preparing = false;
      });
      AppSnackbar.info('SOS cancelled', 'Emergency alert dismissed.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error('Cancel failed', e is ApiException ? e.message : 'Could not cancel SOS. Try again.');
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  void dispose() {
    _sosWorker?.dispose();
    _animationController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Future<void> tripSos() async {
    if (_sending) return;

    final trip = tripStateService.selectedTrip;
    if (trip?.bookingId == null || trip!.bookingId!.isEmpty) {
      _holdController.reset();
      AppSnackbar.error('No active trip', 'SOS needs an active trip.');
      return;
    }

    setState(() => _sending = true);
    try {
      final data = {
        "booking_id": trip.bookingId,
        "latitude": homeController.currentLocation.value.latitude,
        "longitude": homeController.currentLocation.value.longitude,
        // "name": trip.passengerName,
        // "phone": trip.passengerPhone,
      };
      final response = await _tripsRepository.tripSOS(data);
      if (!mounted) return;
      tripStateService.sosActive.value = true;
      setState(() {
        _sending = false;
        _sent = true;
      });
      AppSnackbar.success('Alert sent', response?['message'] ?? 'Emergency alert sent.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = false;
      });
      _holdController.reset();
      AppSnackbar.error('Failed', 'Could not send SOS. Hold again to retry. $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(alignment: Alignment.topLeft, child: SizedBox.shrink()),
            ),
            const SizedBox(height: 20),
            const CustomText(
              text: 'Emergency Help\nNeeded ?',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            CustomText(
              text: _sending
                  ? 'Sending alert…'
                  : _sent
                  ? 'Alert sent'
                  : _preparing
                  ? 'Preparing to send… release to cancel'
                  : 'Press and hold the button for 3 seconds to send an emergency alert.',
              fontSize: 14,
              color: _preparing || _sent || _sending ? AppColors.red : AppColors.grey,
              fontWeight: _preparing || _sent || _sending ? FontWeight.w600 : FontWeight.normal,
              textAlign: TextAlign.center,
            ),
            const Spacer(),

            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red.withValues(alpha: 0.05 + (_animationController.value * 0.05)),
                      ),
                    ),
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red.withValues(alpha: 0.1 + (_animationController.value * 0.05)),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red.withValues(alpha: 0.2 + (_animationController.value * 0.1)),
                      ),
                    ),

                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _holdController.value),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return SizedBox(
                          width: 184,
                          height: 184,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            backgroundColor: AppColors.red.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(AppColors.red),
                          ),
                        );
                      },
                    ),
                    GestureDetector(
                      onLongPressStart: (_) => _startHold(),
                      onLongPressEnd: (_) => _cancelHold(),
                      child: AnimatedScale(
                        scale: _preparing ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.red),
                          child: Center(
                            child: CustomText(
                              text: _sending
                                  ? '…'
                                  : _sent
                                  ? 'SENT'
                                  : 'SOS',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // if (_sent) ...[
            //   const SizedBox(height: 24),
            //   SizedBox(
            //     width: 200,
            //     height: 48,
            //     child: OutlinedButton.icon(
            //       onPressed: () => _cancelSos(tripStateService.selectedTrip?.bookingId ?? ''),
            //       icon: const Icon(Icons.close, color: AppColors.red, size: 18),
            //       label: const CustomText(
            //         text: 'Cancel SOS',
            //         fontSize: 14,
            //         fontWeight: FontWeight.bold,
            //         color: AppColors.red,
            //       ),
            //       style: OutlinedButton.styleFrom(
            //         side: const BorderSide(color: AppColors.red),
            //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //       ),
            //     ),
            //   ),
            // ],
            const Spacer(),
            if (_sent) ...[
              GestureDetector(
                onTap: () => _cancelSos(tripStateService.selectedTrip?.bookingId ?? ''),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.grey300),
                  child: Center(
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey200,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(Icons.close, color: AppColors.darkSlate),
                    ),
                  ),
                ),
              ),
              16.height,
              CustomText(text: 'If you want to cancel click Here', fontSize: 12, color: AppColors.grey),
              40.height,
              Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class RippleAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const RippleAnimation({super.key, required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final progress = (controller.value + index * 0.3) % 1.0;
            final size = 160.0 + (progress * 120);
            final opacity = (1.0 - progress).clamp(0.0, 1.0);

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: opacity * 0.3),
              ),
            );
          }),
        );
      },
    );
  }
}
