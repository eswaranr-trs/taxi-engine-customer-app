import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';

class DottedVerticalLine extends StatelessWidget {
  const DottedVerticalLine({
    super.key,
    this.color = AppColors.grey300,
    this.thickness = .8,
    this.dashLength = 3,
    this.gapLength = 4,
  });

  final Color color;
  final double thickness;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(thickness, double.infinity),
      painter: _DottedVerticalPainter(color: color, thickness: thickness, dashLength: dashLength, gapLength: gapLength),
    );
  }
}

class _DottedVerticalPainter extends CustomPainter {
  const _DottedVerticalPainter({
    required this.color,
    required this.thickness,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double thickness;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final double x = size.width / 2;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dashLength, size.height)), paint);
      y += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_DottedVerticalPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.thickness != thickness ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
