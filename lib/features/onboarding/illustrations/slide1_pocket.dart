import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';

/// Slide 1: Aquarela no seu bolso.
/// Hand-drawn palm + phone with pigment bleeding OUT of the screen onto paper.
/// No box frame — the illustration bleeds onto the paper background.
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

    // === Watercolor stroke that bleeds BEHIND the phone (yellow→sienna) ===
    final bgStrokePaint = Paint()
      ..shader = LinearGradient(
        colors: [Pigment.cadmiumYellow, Pigment.burntSienna],
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

    // === Phone (ultramar) — slightly tilted ===
    canvas.save();
    canvas.translate(w * 0.55, h * 0.5);
    canvas.rotate(-0.08);

    final phonePaint = Paint()..color = Pigment.ultramar;
    final phoneBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.32, height: h * 0.50),
      const Radius.circular(24),
    );
    canvas.drawRRect(phoneBody, phonePaint);

    // Screen (paper white) — the "canvas" inside
    final screenPaint = Paint()..color = Paper.white;
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * 0.27, height: h * 0.42),
      const Radius.circular(6),
    );
    canvas.drawRRect(screenRect, screenPaint);

    // Pigment splash INSIDE the screen (filling more)
    final innerPigment1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Pigment.ultramar,
          Pigment.ultramar.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(-0.04, -0.04), radius: 0.10))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(-w * 0.04, -h * 0.04), 35, innerPigment1);

    final innerPigment2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Pigment.burntSienna,
          Pigment.burntSienna.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(0.04, 0.05), radius: 0.08))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(w * 0.04, h * 0.05), 25, innerPigment2);

    final innerPigment3 = Paint()
      ..color = Pigment.cadmiumYellow.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(0, -h * 0.08), 14, innerPigment3);

    // Notch
    final notchPaint = Paint()..color = Pigment.ultramar;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -h * 0.22), width: w * 0.10, height: 4),
        const Radius.circular(4),
      ),
      notchPaint,
    );

    canvas.restore();

    // === Foreground pigment stroke bleeding OUT of the top of the phone ===
    final outStrokePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Pigment.ultramar, Pigment.cadmiumYellow],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.3))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final outPath = Path();
    outPath.moveTo(w * 0.50, h * 0.22);
    outPath.quadraticBezierTo(w * 0.20, h * 0.18, w * 0.18, h * 0.05);
    outPath.quadraticBezierTo(w * 0.40, h * 0.10, w * 0.55, h * 0.20);
    outPath.close();
    canvas.drawPath(outPath, outStrokePaint);

    // Small drops above the phone
    for (final drop in [
      Offset(w * 0.18, h * 0.05),
      Offset(w * 0.30, h * 0.08),
      Offset(w * 0.45, h * 0.12),
    ]) {
      canvas.drawCircle(drop, 4, outStrokePaint);
    }

    // === Hand: stylized palm emerging from bottom — skin tone (burnt sienna diluted) ===
    final handPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFB8835E), // light skin tone
          Pigment.burntSienna.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    final handPath = Path();
    // Palm curve coming from bottom-right
    handPath.moveTo(w * 0.30, h * 1.02);
    handPath.quadraticBezierTo(w * 0.22, h * 0.82, w * 0.32, h * 0.72);
    handPath.quadraticBezierTo(w * 0.50, h * 0.66, w * 0.68, h * 0.74);
    handPath.quadraticBezierTo(w * 0.85, h * 0.82, w * 0.80, h * 1.02);
    handPath.close();
    canvas.drawPath(handPath, handPaint);

    // 4 finger ridges — clearly visible as soft rounded shapes
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

    // Thumb — sticks out to the left side
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
