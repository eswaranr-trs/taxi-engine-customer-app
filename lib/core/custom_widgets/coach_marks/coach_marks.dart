import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class CoachMark {
  const CoachMark({
    required this.targetKey,
    required this.title,
    required this.description,
    this.accent,
    this.holeRadius = 20,
    this.holePadding = 5,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final Color? accent;
  final double holeRadius;
  final double holePadding;
}

class CoachMarks {
  CoachMarks._();

  static OverlayEntry? _entry;
  static bool get isVisible => _entry != null;
  static final ValueNotifier<bool> isShowing = ValueNotifier<bool>(false);

  static void show(BuildContext context, {required List<CoachMark> steps, VoidCallback? onFinish}) {
    if (_entry != null || steps.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => _CoachMarkView(
        steps: steps,
        onFinish: () {
          dismiss();
          onFinish?.call();
        },
      ),
    );
    overlay.insert(_entry!);
    isShowing.value = true;
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
    isShowing.value = false;
  }
}

class _CoachMarkView extends StatefulWidget {
  const _CoachMarkView({required this.steps, required this.onFinish});

  final List<CoachMark> steps;
  final VoidCallback onFinish;

  @override
  State<_CoachMarkView> createState() => _CoachMarkViewState();
}

class _CoachMarkViewState extends State<_CoachMarkView> {
  static const List<Color> _palette = [
    AppColors.orangeAccent,
    AppColors.purple,
    AppColors.successGreen,
    AppColors.blue500,
    AppColors.red500,
  ];

  static const double _edgeMargin = 20;
  static const double _arrowWidth = 44;
  static const double _arrowHeight = 85;
  static const double _arrowGap = 10;
  static const double _arrowSpace = _arrowHeight + _arrowGap * 2;
  static const double _gap = 12;
  static const double _minCardHeight = 110;
  static const int _maxMissFrames = 12;

  int _index = 0;
  int _missFrames = 0;
  bool _laidOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _laidOut = true);
      _revealTarget(widget.steps[_index]);
    });
  }

  Future<void> _revealTarget(CoachMark step) async {
    final targetContext = step.targetKey.currentContext;
    if (targetContext == null) return;
    if (Scrollable.maybeOf(targetContext) == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.5,
    );
    if (mounted) setState(() {});
  }

  Color get _accent => widget.steps[_index].accent ?? _palette[_index % _palette.length];

  Rect? _targetRect(CoachMark step) {
    final targetContext = step.targetKey.currentContext;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (targetContext == null || overlayBox == null) return null;

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    return box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
  }

  void _go(int next) {
    if (next < 0) return;
    if (next >= widget.steps.length) {
      widget.onFinish();
      return;
    }
    setState(() {
      _index = next;
      _missFrames = 0;
    });
    _revealTarget(widget.steps[next]);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final Rect? rect = _targetRect(step);

    if (rect == null) {
      if (_laidOut) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_missFrames < _maxMissFrames) {
            setState(() => _missFrames++);
          } else {
            _go(_index + 1);
          }
        });
      }
      return const SizedBox.expand();
    }

    final media = MediaQuery.of(context);
    final Size screen = media.size;
    final double safeTop = media.padding.top + 56;
    final double safeBottom = screen.height - media.padding.bottom - 12;

    final Rect hole = rect.inflate(step.holePadding).intersect(Offset.zero & screen);
    if (hole.width <= 0 || hole.height <= 0) return const SizedBox.expand();

    final double radius = math.min(step.holeRadius, hole.shortestSide / 2);

    final double spaceAbove = hole.top - safeTop;
    final double spaceBelow = safeBottom - hole.bottom;
    final bool placeBelow = spaceBelow >= spaceAbove;
    final double available = (placeBelow ? spaceBelow : spaceAbove).clamp(0.0, screen.height);

    final bool fitsBeside = available >= _minCardHeight;
    final bool withArrow = fitsBeside && available >= _minCardHeight + _arrowSpace;
    final double lead = withArrow ? _arrowSpace : _gap;

    return Material(
      color: AppColors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _CoachPainter(hole: hole, radius: radius, accent: _accent),
              ),
            ),
          ),

          if (withArrow) _buildArrow(hole, screen, placeBelow),
          _buildCard(hole, screen, safeTop, safeBottom, placeBelow, available, fitsBeside, lead, step),
          _buildSkipButton(media.padding.top),
        ],
      ),
    );
  }

  Widget _buildArrow(Rect hole, Size screen, bool placeBelow) {
    final bool curlsRight = hole.center.dx < screen.width * 0.5;
    final String asset = curlsRight ? 'assets/icons/right_arrow.svg' : 'assets/icons/left_arrow.svg';

    final double left = (hole.center.dx - _arrowWidth / 2).clamp(_edgeMargin, screen.width - _arrowWidth - _edgeMargin);

    final Widget arrow = SvgPicture.asset(
      asset,
      width: _arrowWidth,
      height: _arrowHeight,
      colorFilter: ColorFilter.mode(_accent, BlendMode.srcIn),
    );

    return Positioned(
      left: left,
      top: placeBelow ? hole.bottom + _arrowGap : hole.top - _arrowGap - _arrowHeight,
      child: IgnorePointer(child: placeBelow ? arrow : Transform.scale(scaleY: -1, child: arrow)),
    );
  }

  Widget _buildSkipButton(double topSafe) {
    return Positioned(
      top: topSafe + 12,
      right: 16,
      child: GestureDetector(
        onTap: widget.onFinish,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.2), blurRadius: 12)],
          ),
          child: const CustomText(text: 'Skip', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
        ),
      ),
    );
  }

  Widget _buildCard(
    Rect hole,
    Size screen,
    double safeTop,
    double safeBottom,
    bool placeBelow,
    double available,
    bool fitsBeside,
    double lead,
    CoachMark step,
  ) {
    final bool isFirst = _index == 0;
    final bool isLast = _index == widget.steps.length - 1;

    final double maxHeight = fitsBeside
        ? (available - lead).clamp(_minCardHeight, screen.height)
        : (safeBottom - safeTop);

    final Widget card = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: Color.alphaBlend(_accent.withValues(alpha: 0.20), AppColors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accent, width: 1),
          boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(
                    text: step.title,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                  ),
                ),
                8.width,
                CustomText(
                  text: '${_index + 1}/${widget.steps.length}',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _accent,
                ),
              ],
            ),
            4.height,
            Flexible(
              child: SingleChildScrollView(
                child: CustomText(
                  text: step.description,
                  fontSize: 11.5,
                  color: AppColors.darkSlate,
                  textAlign: TextAlign.start,
                  maxLines: 6,
                  height: 1.35,
                ),
              ),
            ),
            8.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: isFirst ? null : () => _go(_index - 1),
                  child: CustomText(
                    text: 'Previous',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFirst ? AppColors.grey600 : AppColors.darkSlate,
                  ),
                ),
                12.width,
                Container(width: 1, height: 12, color: _accent.withValues(alpha: 0.4)),
                12.width,
                GestureDetector(
                  onTap: () => _go(_index + 1),
                  child: CustomText(
                    text: isLast ? 'Done' : 'Next',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!fitsBeside) {
      return Positioned(
        left: _edgeMargin,
        right: _edgeMargin,
        top: safeTop,
        bottom: screen.height - safeBottom,
        child: Center(child: card),
      );
    }

    return Positioned(
      left: _edgeMargin,
      right: _edgeMargin,
      top: placeBelow ? hole.bottom + lead : null,
      bottom: placeBelow ? null : screen.height - hole.top + lead,
      child: card,
    );
  }
}

class _CoachPainter extends CustomPainter {
  const _CoachPainter({required this.hole, required this.radius, required this.accent});

  final Rect hole;
  final double radius;
  final Color accent;

  static const double _scrimAlpha = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, Radius.circular(radius));

    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(rrect)),
      Paint()..color = AppColors.white.withValues(alpha: _scrimAlpha),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = accent.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );

    // _paintSparks(canvas);
  }

  // void _paintSparks(Canvas canvas) {
  //   final paint = Paint()
  //     ..color = accent
  //     ..strokeWidth = 2.5
  //     ..strokeCap = StrokeCap.round;

  //   const double len = 9;
  //   const double offset = 7;

  //   void burst(Offset corner, double baseAngle) {
  //     for (final da in [-0.45, 0.0, 0.45]) {
  //       final a = baseAngle + da;
  //       final start = corner + Offset(math.cos(a) * offset, math.sin(a) * offset);
  //       final end = corner + Offset(math.cos(a) * (offset + len), math.sin(a) * (offset + len));
  //       canvas.drawLine(start, end, paint);
  //     }
  //   }

  //   burst(hole.topLeft, math.pi * 1.25);
  //   burst(hole.topRight, math.pi * 1.75);
  // }

  @override
  bool shouldRepaint(_CoachPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.radius != radius || oldDelegate.accent != accent;
}
