import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/controllers/finding_driver_controller.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/service/trip_state_service.dart';

class TripResumeRefresher extends StatefulWidget {
  final Widget child;
  final String label;
  final Future<void> Function()? onRefreshed;

  const TripResumeRefresher({super.key, required this.child, required this.label, this.onRefreshed});

  @override
  State<TripResumeRefresher> createState() => _TripResumeRefresherState();
}

class _TripResumeRefresherState extends State<TripResumeRefresher> with WidgetsBindingObserver {
  static const Duration _settleDelay = Duration(milliseconds: 400);
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final int seq = ++_seq;
    Future.delayed(_settleDelay, () => _refresh(seq));
  }

  Future<void> _refresh(int seq) async {
    if (!mounted || seq != _seq) return;

    if (Get.isRegistered<TripStateService>()) {
      await Get.find<TripStateService>().handleAppResumed();
    }
    if (!mounted || seq != _seq) return;

    if (Get.isRegistered<FindingDriverController>()) {
      await Get.find<FindingDriverController>().refreshAfterResume();
    }
    if (!mounted || seq != _seq) return;

    await widget.onRefreshed?.call();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
