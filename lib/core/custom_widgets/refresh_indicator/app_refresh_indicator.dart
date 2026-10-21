import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';

class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({super.key, required this.onRefresh, required this.slivers, this.controller});

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  static const double _triggerDistance = 110;
  static const double _indicatorExtent = 76;

  bool _pointerDown = false;
  Completer<void>? _release;

  Future<void> _handleRefresh() async {
    if (_pointerDown) {
      _release = Completer<void>();
      await _release!.future;
    }
    await widget.onRefresh();
  }

  void _releasePointer() {
    _pointerDown = false;
    final Completer<void>? pending = _release;
    _release = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  @override
  void dispose() {
    _releasePointer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pointerDown = true,
      onPointerUp: (_) => _releasePointer(),
      onPointerCancel: (_) => _releasePointer(),
      child: CustomScrollView(
        controller: widget.controller,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            refreshTriggerPullDistance: _triggerDistance,
            refreshIndicatorExtent: _indicatorExtent,
            onRefresh: _handleRefresh,
            builder: (context, mode, pulledExtent, triggerDistance, indicatorExtent) => _TaxiPullIndicator(
              mode: mode,
              pulledExtent: pulledExtent,
              triggerDistance: triggerDistance,
              indicatorExtent: indicatorExtent,
            ),
          ),
          ...widget.slivers,
        ],
      ),
    );
  }
}

class _TaxiPullIndicator extends StatefulWidget {
  const _TaxiPullIndicator({
    required this.mode,
    required this.pulledExtent,
    required this.triggerDistance,
    required this.indicatorExtent,
  });

  final RefreshIndicatorMode mode;
  final double pulledExtent;
  final double triggerDistance;
  final double indicatorExtent;

  @override
  State<_TaxiPullIndicator> createState() => _TaxiPullIndicatorState();
}

class _TaxiPullIndicatorState extends State<_TaxiPullIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(_TaxiPullIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) _syncSpin();
  }

  void _syncSpin() {
    final bool busy = widget.mode == RefreshIndicatorMode.refresh || widget.mode == RefreshIndicatorMode.armed;
    if (busy && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!busy && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == RefreshIndicatorMode.inactive) return const SizedBox.shrink();

    final double pullProgress = (widget.pulledExtent / widget.triggerDistance).clamp(0.0, 1.0);
    final bool busy = widget.mode == RefreshIndicatorMode.refresh || widget.mode == RefreshIndicatorMode.armed;

    final double reveal = (pullProgress / 0.35).clamp(0.0, 1.0);

    return Center(
      child: Opacity(
        opacity: widget.mode == RefreshIndicatorMode.done ? pullProgress : reveal,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, _) {
            final double turns = busy ? _spin.value : pullProgress * 0.75;
            final double bob = busy ? math.sin(_spin.value * 2 * math.pi) * 1.5 : 0;

            return Transform.scale(
              scale: 0.7 + (0.3 * reveal),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: turns * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(46, 46),
                        painter: _RingPainter(progress: busy ? 0.78 : pullProgress),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, bob),
                      child: Icon(
                        Icons.local_taxi_rounded,
                        size: 20,
                        color: pullProgress >= 1 || busy ? AppColors.primary : AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 2.6;
    final Rect rect = Offset(stroke / 2 + 3, stroke / 2 + 3) & Size(size.width - stroke - 6, size.height - stroke - 6);

    final Paint track = Paint()
      ..color = AppColors.grey100
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final Paint arc = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary, AppColors.orangeAccent],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.progress != progress;
}
