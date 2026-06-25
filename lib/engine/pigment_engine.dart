import 'dart:math' as math;
import 'dart:ui';

import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// The pigment engine converts raw touch paths into pre-rendered
/// [Stamp]s. It's a pure function: same input → same output, no
/// state, no side effects.
///
/// Four distinct stamp strategies — one per brush tip:
///   - **round**: a clean disc with a soft radial halo of small
///     sub-stamps for the watercolor bleed.
///   - **flat**: an oriented oval that follows the stroke
///     direction; width is fixed, length stretches along the
///     heading. Sub-stamps are spread along the perpendicular
///     to mimic the bristles.
///   - **fan**: a splay of parallel tines (rectangles) along
///     the stroke direction; gaps between tines let the paper
///     show through — that's what makes a fan brush recognizable.
///   - **mop**: a large, soft disc with an irregular jagged
///     edge (mop bristles don't form a clean circle); a few
///     low-alpha sub-stamps extend the halo further than other
///     brushes.
///
/// All four also share wet-on-wet color bleeding: if the brush
/// is wet and the path passes near an existing stroke, the new
/// stamp's color is biased toward the existing one proportional
/// to proximity.
class PigmentEngine {
  const PigmentEngine._();

  /// Maximum number of sub-stamps emitted per waypoint for the
  /// radial bleed effect. Tuned to 5 — enough to look organic,
  /// cheap enough to not stutter on a real finger drag.
  static const int _bleedSamples = 5;

  /// Distance (in pixels) at which a fresh stroke fully mixes into
  /// an existing stroke. Beyond this distance, no mixing happens.
  /// Tuned to ~3x a typical brush size — the visual sweet spot
  /// where watercolors actually spread on paper.
  static const double _wetBleedRadius = 150.0;

  /// Convert a [path] of touch points into renderable stamps.
  ///
  /// [brush] — the active brush (size, opacity, water ratio, type).
  /// [pigment] — the active pigment (color, absorption).
  /// [path] — finger waypoints. Empty list returns empty list.
  /// [existing] — strokes already on the canvas. Used for
  ///   wet-on-wet color bleeding.
  static List<Stamp> stroke({
    required Brush brush,
    required Pigment pigment,
    required List<Offset> path,
    required List<Stroke> existing,
  }) {
    if (path.isEmpty) return const [];

    final random = math.Random(pigment.id.hashCode ^ path.length);
    final stamps = <Stamp>[];

    // Bleed radius is driven by water ratio: dry = 0.4, wet = 1.6.
    final bleedFactor = 0.4 + brush.waterRatio * 1.2;
    // Pigment absorption amplifies bleed — dark pigments spread more.
    final absorptionFactor = 0.8 + pigment.absorption * 0.6;
    final baseRadius = brush.size * bleedFactor * absorptionFactor;

    for (var i = 0; i < path.length; i++) {
      final p = path[i];
      // Heading: direction the finger is moving in. Used by flat
      // and fan brushes to align the stamp with the stroke. For
      // the first point, fall back to the heading of the next
      // segment; if there isn't one (single dot), use 0.
      final prev = i > 0 ? path[i - 1] : null;
      final next = i + 1 < path.length ? path[i + 1] : null;
      final heading = _heading(prev, p, next);

      // Wet-on-wet color mix: if the brush is wet and the path
      // passes near an existing stroke, bias the new stamp color
      // toward the existing one.
      final mixColor = _wetMix(p, brush, pigment, existing);

      // Dispatch to the per-shape strategy. Each branch is
      // independent — no shared "multipliers + radial noise"
      // math that would blur the differences together.
      switch (brush.type) {
        case BrushType.round:
          _emitRound(
            stamps: stamps,
            random: random,
            point: p,
            radius: baseRadius,
            color: mixColor,
            brush: brush,
          );
        case BrushType.flat:
          _emitFlat(
            stamps: stamps,
            random: random,
            point: p,
            radius: baseRadius,
            color: mixColor,
            brush: brush,
            heading: heading,
          );
        case BrushType.fan:
          _emitFan(
            stamps: stamps,
            random: random,
            point: p,
            radius: baseRadius,
            color: mixColor,
            brush: brush,
            heading: heading,
          );
        case BrushType.mop:
          _emitMop(
            stamps: stamps,
            random: random,
            point: p,
            radius: baseRadius,
            color: mixColor,
            brush: brush,
          );
      }
    }

    return stamps;
  }

  /// Convert a single touch waypoint into the stamps that should
  /// appear for that one point. Used for **real-time** rendering:
  /// the canvas emits stamps as the finger moves, not only on lift.
  ///
  /// [previousPoint] — the last waypoint, if any. Used to compute
  /// the stroke heading so flat/fan brushes can orient themselves.
  /// Pass null for the very first waypoint of a stroke.
  static List<Stamp> stamp({
    required Brush brush,
    required Pigment pigment,
    required Offset point,
    required Offset? previousPoint,
    required List<Stroke> existing,
  }) {
    final path = previousPoint != null
        ? <Offset>[previousPoint, point]
        : <Offset>[point];
    return stroke(
      brush: brush,
      pigment: pigment,
      path: path,
      existing: existing,
    );
  }

  // ---------------------------------------------------------------------------
  // Per-shape stamp strategies
  //
  // Each function appends one or more stamps to [stamps]. The
  // strategies are intentionally different in shape, not just in
  // numerical multipliers — that's what makes the brushes visually
  // distinct instead of "same circle, slightly fatter".
  // ---------------------------------------------------------------------------

  /// Round tip: clean center disc + soft halo of small sub-discs.
  /// This is the baseline brush — the others are variations on it.
  static void _emitRound({
    required List<Stamp> stamps,
    required math.Random random,
    required Offset point,
    required double radius,
    required Color color,
    required Brush brush,
  }) {
    // Center stamp (full opacity, no jitter).
    stamps.add(
      Stamp(
        offset: point,
        radius: radius,
        color: color,
        alpha: brush.opacity,
        shape: StampShape.round,
      ),
    );
    // Halo: waterRatio drives the count of sub-stamps.
    final samples = (brush.waterRatio * _bleedSamples).round();
    for (var s = 0; s < samples; s++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = radius * (0.5 + random.nextDouble() * 0.5);
      stamps.add(
        Stamp(
          offset: point +
              Offset(math.cos(angle) * distance, math.sin(angle) * distance),
          radius: radius * (0.3 + random.nextDouble() * 0.4),
          color: color,
          alpha: brush.opacity * (0.3 + random.nextDouble() * 0.4),
          shape: StampShape.round,
        ),
      );
    }
  }

  /// Flat tip: oriented oval that follows the stroke heading,
  /// plus a few bristles spread along the perpendicular axis.
  /// The oval's length stretches along [heading]; the painter
  /// rotates the canvas before drawing.
  static void _emitFlat({
    required List<Stamp> stamps,
    required math.Random random,
    required Offset point,
    required double radius,
    required Color color,
    required Brush brush,
    required double heading,
  }) {
    // Aspect ratio: how much longer than wide the oval is. Flat
    // brushes are typically ~3x longer than wide.
    const aspectRatio = 3.0;
    // A few perpendicular bristles — the visible "flat" texture.
    const bristleCount = 5;
    final bristleSpread = radius * 0.6;

    // Main oval stamp.
    stamps.add(
      Stamp(
        offset: point,
        radius: radius,
        color: color,
        alpha: brush.opacity * 0.85,
        shape: StampShape.oval,
        angle: heading,
        aspectRatio: aspectRatio,
      ),
    );

    // Bristles: thin parallel ovals along the same heading,
    // offset perpendicular to it.
    for (var b = 0; b < bristleCount; b++) {
      // Spread evenly from -bristleSpread to +bristleSpread.
      final t = (b - (bristleCount - 1) / 2) / (bristleCount - 1);
      final perpX = -math.sin(heading);
      final perpY = math.cos(heading);
      final offset = Offset(perpX * bristleSpread * t, perpY * bristleSpread * t);
      // Each bristle is shorter than the main oval and slightly
      // thinner. A bit of random jitter so they don't look stamped.
      final jitterAngle = heading + (random.nextDouble() - 0.5) * 0.08;
      stamps.add(
        Stamp(
          offset: point + offset,
          radius: radius * 0.45,
          color: color,
          alpha: brush.opacity * (0.25 + random.nextDouble() * 0.25),
          shape: StampShape.oval,
          angle: jitterAngle,
          aspectRatio: 4.0,
        ),
      );
    }
  }

  /// Fan tip: a splay of parallel thin rectangles (tines) along
  /// [heading]. Gaps between tines are what makes a fan brush
  /// recognizable — a fan doesn't deposit a continuous stroke,
  /// it deposits several streaks.
  static void _emitFan({
    required List<Stamp> stamps,
    required math.Random random,
    required Offset point,
    required double radius,
    required Color color,
    required Brush brush,
    required double heading,
  }) {
    // Tine configuration: ~6 thin streaks spread across the
    // brush width. Each tine is a rect.
    const tineCount = 6;
    final tineLength = radius * 2.0;
    final tineWidth = (radius * 1.4) / tineCount;
    final totalWidth = tineCount * tineWidth;
    final firstOffset = -totalWidth / 2 + tineWidth / 2;

    // Perpendicular direction for tine spacing.
    final perpX = -math.sin(heading);
    final perpY = math.cos(heading);

    for (var i = 0; i < tineCount; i++) {
      // Evenly spaced perpendicular to heading. A bit of random
      // jitter per tine so it doesn't look mechanical.
      final spacing = firstOffset + i * tineWidth;
      final jitter = (random.nextDouble() - 0.5) * tineWidth * 0.3;
      final tineOffset =
          Offset(perpX * (spacing + jitter), perpY * (spacing + jitter));

      // Some tines are more pigment-loaded than others — that's
      // the "dry brush" effect on a fan brush.
      final load = 0.4 + random.nextDouble() * 0.6;
      // Skip ~15% of tines for the "gappy" fan look.
      if (random.nextDouble() < 0.15) continue;

      stamps.add(
        Stamp(
          offset: point + tineOffset,
          radius: tineWidth * 0.5,
          color: color,
          alpha: brush.opacity * load * 0.7,
          shape: StampShape.fan,
          angle: heading,
          tineCount: 1,
          tineLength: tineLength,
          tineWidth: tineWidth,
        ),
      );
    }
  }

  /// Mop tip: a large, soft disc with an irregular jagged edge.
  /// Mop brushes have splayed bristles — the deposit is bigger
  /// and softer than a round brush, with a fuzzy edge.
  static void _emitMop({
    required List<Stamp> stamps,
    required math.Random random,
    required Offset point,
    required double radius,
    required Color color,
    required Brush brush,
  }) {
    // Main disc — bigger than a round brush, lower opacity, with
    // edge jitter so the painter renders an irregular outline.
    final edgeJitter = radius * 0.15;
    stamps.add(
      Stamp(
        offset: point,
        radius: radius * 1.4,
        color: color,
        alpha: brush.opacity * 0.55,
        shape: StampShape.mop,
        edgeJitter: edgeJitter,
      ),
    );
    // A handful of soft halo sub-stamps with high jitter to
    // extend the splay.
    final samples = (brush.waterRatio * _bleedSamples * 1.4).round();
    for (var s = 0; s < samples; s++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = radius * (0.7 + random.nextDouble() * 0.7);
      stamps.add(
        Stamp(
          offset: point +
              Offset(math.cos(angle) * distance, math.sin(angle) * distance),
          radius: radius * (0.4 + random.nextDouble() * 0.5),
          color: color,
          alpha: brush.opacity * 0.25 * (0.3 + random.nextDouble() * 0.4),
          shape: StampShape.round,
        ),
      );
    }
  }

  /// Heading of the finger at point [p], given the previous and
  /// next waypoints. Falls back to the next segment if no
  /// previous exists, or to 0 (east) if neither does.
  static double _heading(Offset? prev, Offset p, Offset? next) {
    Offset? a;
    Offset? b;
    if (prev != null) {
      a = prev;
      b = p;
    } else if (next != null) {
      a = p;
      b = next;
    } else {
      return 0.0;
    }
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return 0.0;
    return math.atan2(dy, dx);
  }

  /// the original pigment color if no existing stroke is close
  /// enough, or the wet brush is dry (waterRatio near 0).
  static Color _wetMix(
    Offset p,
    Brush brush,
    Pigment pigment,
    List<Stroke> existing,
  ) {
    // Dry brushes don't bleed. This is the biggest visual lever:
    // waterRatio 0 = crisp line, 1 = watercolor pool.
    if (brush.waterRatio < 0.2) return pigment.color;

    // No strokes to mix with — no work to do.
    if (existing.isEmpty) return pigment.color;

    // Find the closest stamp across all existing strokes.
    // **Performance**: first filter by the stroke's bounding box —
    // if the query point is farther than [_wetBleedRadius] from the
    // box, the stroke can't possibly contribute, and we skip the
    // inner stamp loop entirely.
    Stamp? nearestStamp;
    var nearestDistSq = _wetBleedRadius * _wetBleedRadius;

    for (final stroke in existing) {
      if (stroke.stamps.isEmpty) continue;
      final bounds = stroke.bounds;
      final expanded = bounds.inflate(_wetBleedRadius);
      if (p.dx < expanded.left ||
          p.dx > expanded.right ||
          p.dy < expanded.top ||
          p.dy > expanded.bottom) {
        continue;
      }
      for (final stamp in stroke.stamps) {
        final dx = stamp.offset.dx - p.dx;
        final dy = stamp.offset.dy - p.dy;
        final distSq = dx * dx + dy * dy;
        if (distSq < nearestDistSq) {
          nearestDistSq = distSq;
          nearestStamp = stamp;
        }
      }
    }

    if (nearestStamp == null) return pigment.color;

    // Strength of the mix falls off with distance. 0 at the edge
    // of the bleed radius, 1 right on top of the existing stamp.
    final distance = math.sqrt(nearestDistSq);
    final proximity = 1.0 - (distance / _wetBleedRadius);

    // Water amplifies the mix: a wet brush over a wet brush is
    // the classic watercolor pool, but a dry brush over a wet
    // brush barely picks up any color.
    final wetness = brush.waterRatio.clamp(0.0, 1.0);
    final mixAmount = (proximity * wetness).clamp(0.0, 1.0);

    return Color.lerp(pigment.color, nearestStamp.color, mixAmount) ??
        pigment.color;
  }
}
