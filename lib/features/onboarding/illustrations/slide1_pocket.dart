import 'package:flutter/material.dart';

import '../../../theme/tokens/paper.dart';
import '../../../theme/tokens/pigment.dart';

/// Slide 1: Aquarela no seu bolso.
/// Hand-drawn palm + phone with pigment bleeding OUT of the screen onto paper.
class Slide1PocketIllustration extends StatelessWidget {
  const Slide1PocketIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 320),
      painter: _Slide1Painter(),
    );
  }
}

class _Slide1Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // === Background watercolor stroke behind the phone ===
    final bgStrokePaint = Paint()
      ..shader = LinearGradient(
        colors: [BrandPigment.cadmiumYellow, BrandPigment.burntSienna],
      ).createShader(Rect.fromLTWH(0, h * 0.15, w, h * 0.5))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bgPath = Path();
    bgPath.moveTo(w * 0.10, h * 0.45);
    bgPath.quadraticBezierTo(w * 0.30, h * 0.25, w * 0.55, h * 0.40);
    bgPath.quadraticBezierTo(w * 0.85, h * 0.30, w * 0.90, h * 0.55);
    bgPath.quadraticBezierTo(w * 0.65, h * 0.70, w * 0.40, h * 0.55);
    bgPath.quadraticBezierTo(w * 0.15, h * 0.65, w * 0.10, h * 0.45);
    bgPath.close();
    canvas.drawPath(bgPath, bgStrokePaint);

    // === Phone tilted ===
    canvas.save();
    canvas.translate(w * 0.55, h * 0.5);
    canvas.rotate(-0.08);

    final phonePaint = Paint()..color = BrandPigment.ultramar;
    final phoneBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.32, height: h * 0.50),
      const Radius.circular(24),
    );
    canvas.drawRRect(phoneBody, phonePaint);

    final screenPaint = Paint()..color = Paper.white;
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.27, height: h * 0.42),
      const Radius.circular(6),
    );
    canvas.drawRRect(screenRect, screenPaint);

    // === Pigment INSIDE screen — generous gradients ===
    final innerPigment1 = Paint()
      ..shader = RadialGradient(
        colors: [
          BrandPigment.ultramar,
          BrandPigment.ultramar.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(-12, -12), radius: 32))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(-12, -12), 35, innerPigment1);

    final innerPigment2 = Paint()
      ..shader = RadialGradient(
        colors: [
          BrandPigment.burntSienna,
          BrandPigment.burntSienna.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(12, 15), radius: 25))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(12, 15), 25, innerPigment2);

    final innerPigment3 = Paint()
      ..color = BrandPigment.cadmiumYellow.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(const Offset(0, -25), 14, innerPigment3);

    // Notch
    final notchPaint = Paint()..color = BrandPigment.ultramar;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -70), width: 32, height: 4),
        const Radius.circular(4),
      ),
      notchPaint,
    );

    canvas.restore();

    // === Pigment bleeding OUT of the top of phone ===
    final outStrokePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [BrandPigment.ultramar, BrandPigment.cadmiumYellow],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.3))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final outPath = Path();
    outPath.moveTo(w * 0.50, h * 0.22);
    outPath.quadraticBezierTo(w * 0.20, h * 0.18, w * 0.18, h * 0.05);
    outPath.quadraticBezierTo(w * 0.40, h * 0.10, w * 0.55, h * 0.20);
    outPath.close();
    canvas.drawPath(outPath, outStrokePaint);

    for (final drop in [
      Offset(w * 0.18, h * 0.05),
      Offset(w * 0.30, h * 0.08),
      Offset(w * 0.45, h * 0.12),
    ]) {
      canvas.drawCircle(drop, 4, outStrokePaint);
    }

    // === Hand: skin tone, clearly drawn ===
    final handPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFB8835E),
          BrandPigment.burntSienna.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    final handPath = Path();
    handPath.moveTo(w * 0.30, h * 1.02);
    handPath.quadraticBezierTo(w * 0.22, h * 0.82, w * 0.32, h * 0.72);
    handPath.quadraticBezierTo(w * 0.50, h * 0.66, w * 0.68, h * 0.74);
    handPath.quadraticBezierTo(w * 0.85, h * 0.82, w * 0.80, h * 1.02);
    handPath.close();
    canvas.drawPath(handPath, handPaint);

    // 4 finger ridges
    final fingerPaint = Paint()
      ..color = const Color(0xFFA07248).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final fx = w * 0.36 + (i * w * 0.075);
      final fy = h * 0.74 - (i.isEven ? h * 0.02 : h * 0.04);
      final finger = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(fx, fy), width: 14, height: 26),
        const Radius.circular(7),
      );
      canvas.drawRRect(finger, fingerPaint);
    }

    // Thumb
    final thumbPaint = Paint()
      ..color = const Color(0xFFA07248).withValues(alpha: 0.85);
    final thumbPath = Path();
    thumbPath.moveTo(w * 0.32, h * 0.76);
    thumbPath.quadraticBezierTo(w * 0.22, h * 0.78, w * 0.20, h * 0.86);
    thumbPath.quadraticBezierTo(w * 0.22, h * 0.92, w * 0.32, h * 0.88);
    thumbPath.close();
    canvas.drawPath(thumbPath, thumbPaint);
  }

  @override
  bool shouldRepaint(_Slide1Painter oldDelegate) => false;
}
