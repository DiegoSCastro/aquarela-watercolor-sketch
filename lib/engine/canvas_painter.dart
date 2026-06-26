import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// Paints a list of finalized [Stroke]s plus an optional live
/// (in-progress) stroke, onto a canvas.
///
/// Each [Stamp] carries a [StampShape] — the painter dispatches
/// to a shape-specific draw call:
///   - [StampShape.round]  -> drawCircle with a soft blur halo
///   - [StampShape.oval]   -> rotated drawOval, no heavy blur
///     (blur on a rotated oval washes out the elongation, killing
///     the flat-brush look)
///   - [StampShape.fan]    -> thin drawRect tines spread along
///     the stroke heading; no blur (would fuse tines together)
///   - [StampShape.mop]    -> drawCircle with edge jitter so the
///     outline is irregular; soft blur to soften the jitter
///
/// **Performance**:
/// 1. The finalized strokes and the live stroke are passed
///    separately so we don't allocate a combined list per frame.
/// 2. [Paint] is reused across stamps — only [Paint.color] is
///    mutated. Skia fuses the color into the same op.
/// 3. [shouldRepaint] compares strokes by identity first.
class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.strokes,
    required this.paperColor,
    this.liveStroke,
  });

  final List<Stroke> strokes;
  final Color paperColor;

  /// The in-progress (live) stroke. Rendered as a separate
  /// logical layer — no list copying needed.
  final Stroke? liveStroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Paper background.
    final bgPaint = Paint()..color = paperColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // One Paint instance reused across stamps; only color +
    // blendMode + maskFilter are swapped per shape.
    final paint = Paint()..blendMode = BlendMode.srcOver;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    final live = liveStroke;
    if (live != null) {
      _drawStroke(canvas, live, paint);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke, Paint paint) {
    for (final stamp in stroke.stamps) {
      _drawStamp(canvas, stamp, paint);
    }
  }

  void _drawStamp(Canvas canvas, Stamp stamp, Paint paint) {
    paint.color = stamp.color.withValues(alpha: stamp.alpha);
    switch (stamp.shape) {
      case StampShape.round:
        // Soft blur halo gives the wet-on-paper look.
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(stamp.offset, stamp.radius, paint);
      case StampShape.oval:
        // No blur: rotated ovals + blur = mush. The watercolor
        // effect comes from the bristle stamps' lower alpha.
        paint.maskFilter = null;
        canvas.save();
        canvas.translate(stamp.offset.dx, stamp.offset.dy);
        canvas.rotate(stamp.angle);
        final semiMinor = stamp.radius;
        final semiMajor = stamp.radius * stamp.aspectRatio;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: semiMajor * 2,
            height: semiMinor * 2,
          ),
          paint,
        );
        canvas.restore();
      case StampShape.fan:
        // A fan stamp is a single tine: a thin rect aligned
        // along the stamp's angle.
        paint.maskFilter = null;
        canvas.save();
        canvas.translate(stamp.offset.dx, stamp.offset.dy);
        canvas.rotate(stamp.angle);
        // Tine extends from the center forward along the heading.
        final length = stamp.tineLength;
        final width = stamp.tineWidth;
        // Center the rect along the heading axis. The tine starts
        // a bit before the center (so it extends both ways slightly)
        // — that's how a fan brush contacts the paper.
        final rect = Rect.fromCenter(
          center: Offset(length * 0.25, 0),
          width: length,
          height: width,
        );
        // Round the ends slightly for a softer deposit.
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(width * 0.4)),
          paint,
        );
        canvas.restore();
      case StampShape.mop:
        // Irregular disc: small soft blobs scattered around the
        // perimeter within the edge jitter radius, with a softer
        // blur than round.
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        // Slightly translucent fill behind the jitter blobs to
        // make the disc feel continuous even with the irregular
        // edge.
        paint.color = paint.color.withValues(alpha: stamp.alpha * 0.4);
        canvas.drawCircle(stamp.offset, stamp.radius, paint);
        // Scatter edge blobs around the perimeter.
        final jitter = stamp.edgeJitter;
        final perimeterCount = 14;
        for (var i = 0; i < perimeterCount; i++) {
          final a = (i / perimeterCount) * 2 * math.pi;
          // Pseudo-random offset within the jitter band — using
          // a deterministic wave pattern so the painter stays
          // pure (no hidden state).
          final wobble = math.sin(a * 3 + stamp.offset.dx) * 0.5 +
              math.cos(a * 5 + stamp.offset.dy) * 0.5;
          final r = stamp.radius + wobble * jitter;
          final blobRadius = stamp.radius * 0.32;
          paint.color = paint.color.withValues(
            alpha: stamp.alpha * (0.35 + wobble.abs() * 0.5),
          );
          canvas.drawCircle(
            Offset(
              stamp.offset.dx + math.cos(a) * r,
              stamp.offset.dy + math.sin(a) * r,
            ),
            blobRadius,
            paint,
          );
        }
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
