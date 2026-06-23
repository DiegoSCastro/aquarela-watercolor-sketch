import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// Paints a list of [Stroke]s onto a canvas. Each stroke is rendered
/// as a list of circles (one per stamp). Paper texture is composited
/// in v2 (PR 2.1) — v1 just paints strokes on the paper background.
class CanvasPainter extends CustomPainter {
  const CanvasPainter({required this.strokes, required this.paperColor});

  final List<Stroke> strokes;
  final Color paperColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Paper background.
    final bgPaint = Paint()..color = paperColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Strokes. We use SrcOver so dark pigments stack and form richer
    // pools where the user paints multiple times.
    final strokePaint = Paint()..blendMode = BlendMode.srcOver;

    for (final stroke in strokes) {
      for (final stamp in stroke.stamps) {
        strokePaint.color = stamp.color.withValues(alpha: stamp.alpha);
        canvas.drawCircle(stamp.offset, stamp.radius, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter old) {
    return old.strokes != strokes || old.paperColor != paperColor;
  }
}
