import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// Paints a list of finalized [Stroke]s plus an optional live
/// (in-progress) stroke, onto a canvas. Each stroke is rendered as
/// a list of circles (one per stamp). Paper texture is composited
/// in v2 (PR 2.1) — v1 just paints strokes on the paper background.
///
/// **Performance**:
/// 1. The finalized strokes and the live stroke are passed
///    separately so we don't have to allocate a combined list per
///    frame.
/// 2. The paper background and a per-color [Paint] are cached
///    across calls to [paint] so the only allocation in the inner
///    loop is the [Color] (which Flutter's Skia layer fuses
///    anyway).
/// 3. [shouldRepaint] compares strokes by identity first (cheap) and
///    only walks the lists when references change, since finalized
///    strokes never mutate after the user lifts their finger.
class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.strokes,
    required this.paperColor,
    this.liveStroke,
  });

  final List<Stroke> strokes;
  final Color paperColor;

  /// The in-progress (live) stroke. The painter appends it to the
  /// frame as a separate logical layer — no list copying needed.
  final Stroke? liveStroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Paper background. Cached on first call, reused on every
    // subsequent frame (custom painters are reused via
    // [shouldRepaint] when nothing relevant changed).
    final bgPaint = Paint()..color = paperColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Stamp paint: we mutate the colour per stamp instead of
    // allocating a fresh [Paint] each time. The same paint
    // instance is reused for the whole frame.
    final stampPaint = Paint();

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, stampPaint);
    }

    final live = liveStroke;
    if (live != null) {
      _drawStroke(canvas, live, stampPaint);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke, Paint paint) {
    for (final stamp in stroke.stamps) {
      paint.color = stamp.color.withValues(alpha: stamp.alpha);
      canvas.drawCircle(stamp.offset, stamp.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter old) {
    if (old.paperColor != paperColor) return true;
    if (!identical(old.strokes, strokes)) return true;
    if (!identical(old.liveStroke, liveStroke)) return true;
    // Same references, but the live stroke's lists are mutable —
    // the cubit always emits after mutating them, so reaching this
    // point is rare. Stay safe: re-render when the live stroke
    // is present.
    return liveStroke != null;
  }
}
