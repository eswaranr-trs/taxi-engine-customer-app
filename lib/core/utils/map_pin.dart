import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPin {
  static final Map<String, BitmapDescriptor> _cache = <String, BitmapDescriptor>{};

  static const Offset anchor = Offset(0.5, 1.0);

  static Future<BitmapDescriptor> build({
    required Color color,
    String? label,
    IconData? glyph,
    double size = 44,
  }) async {
    final String key = '$color|${label ?? ''}|${glyph?.codePoint ?? 0}|$size';
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) return cached;

    final double dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final double w = size;
    final double h = size * 1.3;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    final double r = w / 2 - 3;
    final double cx = w / 2;
    final double cy = r + 3;
    final double tipY = h - 3;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 4), width: w * 0.46, height: w * 0.15),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    final Path body = Path()
      ..moveTo(cx, tipY)
      ..cubicTo(cx - r * 0.92, cy + r * 0.95, cx - r, cy + r * 0.3, cx - r, cy)
      ..arcToPoint(Offset(cx + r, cy), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(cx + r, cy + r * 0.3, cx + r * 0.92, cy + r * 0.95, cx, tipY)
      ..close();

    final Rect bounds = Rect.fromLTWH(0, 0, w, h);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lift(color, 0.18), color],
        ).createShader(bounds),
    );

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );

    final double innerR = r * 0.54;
    canvas.drawCircle(Offset(cx, cy), innerR, Paint()..color = Colors.white);

    final TextSpan span = glyph != null
        ? TextSpan(
            text: String.fromCharCode(glyph.codePoint),
            style: TextStyle(
              fontSize: innerR * 1.5,
              color: color,
              fontFamily: glyph.fontFamily,
              package: glyph.fontPackage,
            ),
          )
        : TextSpan(
            text: label ?? '',
            style: TextStyle(
              fontSize: innerR * 1.25,
              color: color,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          );

    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    painter.paint(canvas, Offset(cx - painter.width / 2, cy - painter.height / 2));

    final ui.Image image = await recorder.endRecording().toImage((w * dpr).round(), (h * dpr).round());
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;

    final descriptor = BitmapDescriptor.bytes(bytes.buffer.asUint8List(), imagePixelRatio: dpr);
    _cache[key] = descriptor;
    return descriptor;
  }

  static Color _lift(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
