import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

const List<Color> _coachPalette = [
  AppColors.orangeAccent,
  AppColors.purple,
  AppColors.successGreen,
  AppColors.blue500,
  AppColors.red500,
];

class CoachStep {
  const CoachStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.accent,
    this.holeRadius = 20,
    this.holePadding = 8,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;

  final Color? accent;

  final double holeRadius;
  final double holePadding;
}

class HomeCoachMarks extends StatefulWidget {
  const HomeCoachMarks({super.key, required this.steps, required this.onFinish});

  final List<CoachStep> steps;
  final VoidCallback onFinish;

  @override
  State<HomeCoachMarks> createState() => _HomeCoachMarksState();
}

class _HomeCoachMarksState extends State<HomeCoachMarks> with SingleTickerProviderStateMixin {
  int _index = 0;

  bool _laidOut = false;

  int _missFrames = 0;
  static const int _maxMissFrames = 12;
  static const double _arrowWidth = 54;
  static const double _arrowHeight = 96;
  static const double _cardMargin = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _laidOut = true);
    });
  }

  @override
  void dispose() {
    // _glow.dispose();
    super.dispose();
  }

  Color get _accent => widget.steps[_index].accent ?? _coachPalette[_index % _coachPalette.length];

  Rect? _targetRect(CoachStep step) {
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

    final Size screen = MediaQuery.of(context).size;
    final Rect hole = rect.inflate(step.holePadding);
    final bool cardBelow = hole.center.dy < screen.height * 0.45;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(hole: hole, radius: step.holeRadius, accent: _accent),
              ),
            ),
          ),

          _buildSkipButton(),
          _buildArrow(hole, screen, cardBelow),
          _buildCard(hole, screen, cardBelow, step),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 16,
      child: GestureDetector(
        onTap: widget.onFinish,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
          child: const CustomText(text: 'Skip', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.black),
        ),
      ),
    );
  }

  Widget _buildArrow(Rect hole, Size screen, bool cardBelow) {
    final bool curlsRight = hole.center.dx < screen.width * 0.5;
    final String asset = curlsRight ? 'assets/icons/right_arrow.svg' : 'assets/icons/left_arrow.svg';

    final double left = (hole.center.dx - _arrowWidth / 2).clamp(_cardMargin, screen.width - _arrowWidth - _cardMargin);

    final Widget arrow = SvgPicture.asset(
      asset,
      width: _arrowWidth,
      height: _arrowHeight,
      colorFilter: ColorFilter.mode(_accent, BlendMode.srcIn),
    );

    return Positioned(
      left: left,
      top: cardBelow ? hole.bottom + 12 : hole.top - _arrowHeight - 12,
      child: IgnorePointer(child: cardBelow ? Transform.scale(scaleY: -1, child: arrow) : arrow),
    );
  }

  Widget _buildCard(Rect hole, Size screen, bool cardBelow, CoachStep step) {
    final bool isFirst = _index == 0;
    final bool isLast = _index == widget.steps.length - 1;

    return Positioned(
      left: _cardMargin,
      right: _cardMargin,
      top: cardBelow ? hole.bottom + _arrowHeight + 24 : null,
      bottom: cardBelow ? null : (screen.height - hole.top) + _arrowHeight + 24,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent, width: 1.5),
          boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    textAlign: TextAlign.start,
                  ),
                ),
                8.width,
                CustomText(
                  text: '${_index + 1} of ${widget.steps.length}',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _accent,
                ),
              ],
            ),
            6.height,
            CustomText(
              text: step.description,
              fontSize: 12,
              color: AppColors.grey500,
              textAlign: TextAlign.start,
              height: 1.4,
            ),
            10.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: isFirst ? null : () => _go(_index - 1),
                  child: CustomText(
                    text: 'Previous',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFirst ? AppColors.grey300 : AppColors.grey500,
                  ),
                ),
                12.width,
                Container(width: 1, height: 12, color: AppColors.grey200),
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
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole, required this.radius, required this.accent});

  final Rect hole;
  final double radius;
  final Color accent;

  static const double _scrimAlpha = 0.32;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, Radius.circular(radius));

    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(rrect)),
      Paint()..color = AppColors.black.withValues(alpha: _scrimAlpha),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = accent.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.radius != radius || oldDelegate.accent != accent;
}
