import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';

/// Slide 2: Pigmento que respira.
/// Organic, asymmetric pigment diffusion — like real wet-on-wet watercolor.
class Slide2BleedIllustration extends StatelessWidget {
  const Slide2BleedIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 320),
      painter: _Slide2Painter(),
    );
  }
}

class _Slide2Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.46, h * 0.52);

    // === Asymmetric bleed halos — irregular radii + offsets ===
    final rng = math.Random(7);
    final halos = [
      _Halo(radius: 100, opacity: 0.18, offset: const Offset(-8, -4), blur: 14),
      _Halo(radius: 78, opacity: 0.28, offset: const Offset(6, 8), blur: 12),
      _Halo(radius: 58, opacity: 0.40, offset: const Offset(-4, 6), blur: 10),
      _Halo(radius: 42, opacity: 0.55, offset: const Offset(8, -6), blur: 8),
    ];

    for (final halo in halos) {
      final paint = Paint()
        ..color = BrandPigment.ultramar.withValues(alpha: halo.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, halo.blur);
      canvas.drawCircle(center + halo.offset, halo.radius, paint);
    }

    // === Core pigment blob — irregular (not perfect circle) ===
    final corePath = Path();
    final coreRadius = 36.0;
    final points = 18;
    for (var i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final jitter = 1.0 + (rng.nextDouble() - 0.5) * 0.25;
      final r = coreRadius * jitter;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        corePath.moveTo(center.dx + x, center.dy + y);
      } else {
        corePath.lineTo(center.dx + x, center.dy + y);
      }
    }
    corePath.close();
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          BrandPigment.burntSienna,
          const Color(0xFF6B3F26),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawPath(corePath, corePaint);

    // === Granulation noise — denser, more visible ===
    final granPaint = Paint()
      ..color = const Color(0xFF3A1F0F).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    for (var i = 0; i < 60; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final r = rng.nextDouble() * (coreRadius - 4);
      final dx = math.cos(angle) * r;
      final dy = math.sin(angle) * r;
      final size = 0.8 + rng.nextDouble() * 1.6;
      canvas.drawCircle(center + Offset(dx, dy), size, granPaint);
    }

    // === Pooling edge — darker pigment accumulating at the bottom of the blob ===
    final poolingPaint = Paint()
      ..color = const Color(0xFF4A2A18).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 12; i++) {
      final angle = math.pi / 2 + (rng.nextDouble() - 0.5) * 1.2;
      final r = coreRadius * (0.85 + rng.nextDouble() * 0.15);
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      canvas.drawCircle(
        center + Offset(x, y),
        2.5 + rng.nextDouble() * 2,
        poolingPaint,
      );
    }

    // === Cauliflowers — small organic blebs spreading outward (asymmetric positions) ===
    final cauliflowerPaint = Paint()
      ..color = BrandPigment.ultramar.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final cauliflowers = [
      Offset(w * 0.68, h * 0.38),
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.72, h * 0.58),
      Offset(w * 0.78, h * 0.46),
    ];
    for (final c in cauliflowers) {
      canvas.drawCircle(c, 5, cauliflowerPaint);
      canvas.drawCircle(c + const Offset(8, 3), 2.5, cauliflowerPaint);
      canvas.drawCircle(c + const Offset(-5, 6), 3, cauliflowerPaint);
    }

    // === Water drops above — yellow with elongated teardrop shape ===
    final waterPaint = Paint()
      ..color = BrandPigment.cadmiumYellow.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (final drop in [
      Offset(w * 0.42, h * 0.12),
      Offset(w * 0.55, h * 0.08),
    ]) {
      final dropPath = Path();
      dropPath.moveTo(drop.dx, drop.dy - 10);
      dropPath.quadraticBezierTo(
        drop.dx - 6,
        drop.dy + 4,
        drop.dx,
        drop.dy + 7,
      );
      dropPath.quadraticBezierTo(
        drop.dx + 6,
        drop.dy + 4,
        drop.dx,
        drop.dy - 10,
      );
      dropPath.close();
      canvas.drawPath(dropPath, waterPaint);
    }
  }

  @override
  bool shouldRepaint(_Slide2Painter oldDelegate) => false;
}

class _Halo {
  const _Halo({
    required this.radius,
    required this.opacity,
    required this.offset,
    required this.blur,
  });
  final double radius;
  final double opacity;
  final Offset offset;
  final double blur;
}
