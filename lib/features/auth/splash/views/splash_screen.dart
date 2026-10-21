import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';
import 'package:smart_auth/smart_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

const Duration _introDuration = Duration(milliseconds: 2200);

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final AnimationController _orbit;
  late final AnimationController _gloss;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _orbitFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _barFade;

  static const String _brand = 'Orange';
  static const String _suffix = 'Taxi';
  static const String _wordmark = '$_brand $_suffix';

  final List<Animation<double>> _charFade = [];
  final List<Animation<double>> _charSlide = [];

  Future<String?> logAppSignature() async {
    if (!kDebugMode || !GetPlatform.isAndroid) return null;
    final res = await SmartAuth.instance.getAppSignature();
    final String? appSignature = res.data;
    debugPrint('App Signature: $appSignature');
    if (appSignature == null) debugPrint('App Signature failed: ${res.error}');
    return appSignature;
  }

  @override
  void initState() {
    super.initState();
    logAppSignature(); // 8+UiKoWOQMB

    _intro = AnimationController(vsync: this, duration: _introDuration);
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _orbit = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _gloss = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

    _logoScale = Tween<double>(begin: 0.74, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.40)));

    _logoFade = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.28));
    _orbitFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.24, 0.46, curve: Curves.easeOut),
    );

    for (int i = 0; i < _wordmark.length; i++) {
      final double start = (0.34 + i * 0.030).clamp(0.0, 1.0);
      final double end = (start + 0.22).clamp(0.0, 1.0);
      final curve = CurvedAnimation(
        parent: _intro,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
      _charFade.add(curve);
      _charSlide.add(Tween<double>(begin: 14.0, end: 0.0).animate(curve));
    }

    _taglineFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
    );
    _barFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
    );

    _intro.forward();

    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _orbit.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _gloss.repeat();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _orbit.dispose();
    _gloss.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.backgroundCream, AppColors.backgroundBeige, AppColors.backgroundOffWhite],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          _buildAmbientGlow(),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 34),
                _buildWordmark(),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _taglineFade,
                  child: const CustomText(
                    text: 'Let’s go.',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                    letterSpacing: 3.2,
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: FadeTransition(opacity: _barFade, child: _buildProgressDots()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final double t = _ambient.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -90 + math.sin(t) * 18,
              left: -70 + math.cos(t) * 22,
              child: _glowBlob(300, AppColors.primary.withValues(alpha: 0.16)),
            ),
            Positioned(
              bottom: -120 + math.cos(t) * 20,
              right: -90 + math.sin(t) * 16,
              child: _glowBlob(340, AppColors.orange.withValues(alpha: 0.20)),
            ),
          ],
        );
      },
    );
  }

  Widget _glowBlob(double size, Color color) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 190,
      width: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _orbitFade,
            child: RotationTransition(
              turns: _orbit,
              child: const CustomPaint(size: Size(168, 168), painter: _OrbitPainter()),
            ),
          ),
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Container(
                height: 118,
                width: 118,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset('assets/images/new_logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordmark() {
    final Widget letters = AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_wordmark.length, (i) {
            final bool isBrand = i < _brand.length;
            return Opacity(
              opacity: _charFade[i].value,
              child: Transform.translate(
                offset: Offset(0, _charSlide[i].value),
                child: CustomText(
                  text: _wordmark[i],
                  fontSize: 30,
                  fontWeight: isBrand ? FontWeight.w800 : FontWeight.w500,
                  color: isBrand ? AppColors.primary : AppColors.darkText,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }),
        );
      },
    );

    return AnimatedBuilder(
      animation: _gloss,
      builder: (context, child) {
        final double x = _gloss.value * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 0.5, 0),
            end: Alignment(x + 0.5, 0),
            colors: [AppColors.transparent, AppColors.white.withValues(alpha: 0.75), AppColors.transparent],
          ).createShader(bounds),
          child: child,
        );
      },
      child: letters,
    );
  }

  Widget _buildProgressDots() {
    return AnimatedBuilder(
      animation: _orbit,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double phase = (_orbit.value + i * 0.18) % 1.0;

            final double wave = math.sin(phase * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.25 + wave * 0.65),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.primary.withValues(alpha: 0.10),
    );

    const double sweep = math.pi * 0.62;
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      colors: [AppColors.primary.withValues(alpha: 0.0), AppColors.primary],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}
