import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class AdvancePaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final VoidCallback onDone;

  const AdvancePaymentSuccessScreen({super.key, required this.amount, required this.onDone});

  @override
  State<AdvancePaymentSuccessScreen> createState() => _AdvancePaymentSuccessScreenState();
}

class _AdvancePaymentSuccessScreenState extends State<AdvancePaymentSuccessScreen> {
  Timer? _timer;
  bool _done = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        _finish();
      } else {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      }
    });
  }

  void _finish() {
    if (_done) return;

    _done = true;
    _timer?.cancel();

    if (mounted) Navigator.of(context).pop();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  8.height,
                  Lottie.asset('assets/lotties/success.json', height: 160, width: 160, repeat: false),
                  4.height,
                  const CustomText(
                    text: 'Advance Payment Successful',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.center,
                  ),
                  10.height,
                  CustomText(
                    text: '₹${widget.amount.toStringAsFixed(2)}',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  8.height,
                  const CustomText(
                    text: 'Your advance payment has been received and your booking is now secured.',
                    fontSize: 13,
                    color: AppColors.slate500,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  20.height,
                  CustomText(text: 'Continuing in $_countdown seconds...', fontSize: 12, color: AppColors.grey400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
