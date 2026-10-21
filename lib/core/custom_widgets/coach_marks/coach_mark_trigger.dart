import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/coach_marks/coach_marks.dart';
import 'package:orange_taxi_customer_app/core/services/local_storage_service/local_storage_service.dart';

class CoachMarkTrigger extends StatefulWidget {
  const CoachMarkTrigger({
    super.key,
    required this.storageKey,
    required this.steps,
    this.delay = const Duration(milliseconds: 900),
  });

  final String storageKey;
  final List<CoachMark> Function() steps;
  final Duration delay;

  @override
  State<CoachMarkTrigger> createState() => _CoachMarkTriggerState();
}

class _CoachMarkTriggerState extends State<CoachMarkTrigger> {
  @override
  void initState() {
    super.initState();
    _maybeShow();
  }

  @override
  void dispose() {
    if (CoachMarks.isVisible) CoachMarks.dismiss();
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!await LocalStorageService.isSignupUser()) return;
    if (await LocalStorageService.hasSeenCoachMark(widget.storageKey)) return;
    await Future.delayed(widget.delay);
    if (!mounted || CoachMarks.isVisible) return;

    final steps = widget.steps().where((s) => _isRendered(s.targetKey)).toList();
    if (steps.isEmpty) return;

    CoachMarks.show(context, steps: steps, onFinish: () => LocalStorageService.setSeenCoachMark(widget.storageKey));
  }

  bool _isRendered(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize && box.size.width > 1 && box.size.height > 1;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
