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
/// Three effects drive the look:
/// 1. **Path stamps** — one stamp per waypoint, radius = brush.size
/// 2. **Radial bleed** — waterRatio amplifies the stamp radius and
///    adds N sub-stamps with random offsets for organic edges
/// 3. **Wet-on-wet bleeding** — when a new stroke passes near an
///    existing stroke with high water, the colors mix; the new
///    stamp's color is biased toward the existing one proportional
///    to proximity
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
  ///   wet-on-wet color bleeding (PR 2.1).
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

    // Brush-type multipliers — round keeps its base radius; flat
    // elongates horizontally; fan adds many sub-stamps with high
    // jitter for a dry-brush look; mop is large and soft.
    final typeMult = _typeMultipliers(brush.type);

    for (final p in path) {
      // Wet-on-wet color mix: if the brush is wet and the path
      // passes near an existing stroke, bias the new stamp color
      // toward the existing one. Returns the original color if
      // there is no nearby stroke.
      final mixColor = _wetMix(p, brush, pigment, existing);

      // Center stamp (always full size, no jitter).
      stamps.add(
        Stamp(
          offset: p,
          radius: baseRadius * typeMult.radius,
          color: mixColor,
          alpha: brush.opacity,
        ),
      );

      // Bleed sub-stamps: small offsets and slightly different
      // radii, for organic edges. Number of sub-stamps scales with
      // waterRatio AND brush type: fan brushes always emit many,
      // mop brushes emit a wide halo, flat brushes a tight row.
      final samples = (brush.waterRatio * _bleedSamples * typeMult.samples)
          .round();
      for (var s = 0; s < samples; s++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = baseRadius *
            typeMult.radius *
            (0.5 + random.nextDouble() * 0.5);
        final dx = math.cos(angle) * distance * typeMult.spreadX;
        final dy = math.sin(angle) * distance * typeMult.spreadY;
        final subRadius = baseRadius *
            typeMult.radius *
            (0.3 + random.nextDouble() * 0.4);
        final subAlpha =
            brush.opacity * typeMult.subAlpha * (0.3 + random.nextDouble() * 0.4);

        stamps.add(
          Stamp(
            offset: p + Offset(dx, dy),
            radius: subRadius,
            color: mixColor,
            alpha: subAlpha.clamp(0.0, 1.0),
          ),
        );
      }
    }

    return stamps;
  }

  /// Per-brush-type tuning. Keeps the base engine math intact
  /// while letting each tip behave like its real-world counterpart.
  static _BrushTuning _typeMultipliers(BrushType type) {
    switch (type) {
      case BrushType.round:
        return const _BrushTuning(
          radius: 1.0,
          samples: 1.0,
          spreadX: 1.0,
          spreadY: 1.0,
          subAlpha: 1.0,
        );
      case BrushType.flat:
        // Flat brushes leave a horizontal streak — wider X spread,
        // tighter Y. Fewer jittered sub-stamps.
        return const _BrushTuning(
          radius: 1.1,
          samples: 0.6,
          spreadX: 1.4,
          spreadY: 0.5,
          subAlpha: 0.85,
        );
      case BrushType.fan:
        // Fan brushes spread pigment unevenly — many small, dry
        // sub-stamps with chaotic offsets.
        return const _BrushTuning(
          radius: 0.9,
          samples: 1.6,
          spreadX: 1.2,
          spreadY: 1.2,
          subAlpha: 0.5,
        );
      case BrushType.mop:
        // Mop brushes are big and soft — large radius, low alpha
        // per sub-stamp, wide halo.
        return const _BrushTuning(
          radius: 1.6,
          samples: 1.4,
          spreadX: 1.0,
          spreadY: 1.0,
          subAlpha: 0.6,
        );
    }
  }

  /// Convert a single touch waypoint into the stamps that should
  /// appear for that one point. Used for **real-time** rendering:
  /// the canvas emits stamps as the finger moves, not only on lift.
  ///
  /// [brush] / [pigment] — the active tool.
  /// [point] — the new waypoint.
  /// [existing] — strokes already on the canvas. Used for
  ///   wet-on-wet color bleeding. The stroke being currently
  ///   drawn (if any) is represented here as a [Stroke] whose
  ///   `stamps` field carries the stamps already emitted for the
  ///   same drag — that way wet-on-wet can blend within the same
  ///   stroke as it grows.
  static List<Stamp> stamp({
    required Brush brush,
    required Pigment pigment,
    required Offset point,
    required List<Stroke> existing,
  }) {
    return stroke(
      brush: brush,
      pigment: pigment,
      path: [point],
      existing: existing,
    );
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
    // Existing strokes that have no stamps yet (still being drawn)
    // are skipped — we don't bleed into the live in-progress stroke.
    Stroke? nearestStroke;
    Stamp? nearestStamp;
    var nearestDistSq = double.infinity;

    for (final stroke in existing) {
      if (stroke.stamps.isEmpty) continue;
      for (final stamp in stroke.stamps) {
        final dx = stamp.offset.dx - p.dx;
        final dy = stamp.offset.dy - p.dy;
        final distSq = dx * dx + dy * dy;
        if (distSq < nearestDistSq) {
          nearestDistSq = distSq;
          nearestStamp = stamp;
          nearestStroke = stroke;
        }
      }
    }

    if (nearestStamp == null || nearestStroke == null) return pigment.color;

    // Strength of the mix falls off with distance. 0 at the edge
    // of the bleed radius, 1 right on top of the existing stamp.
    final distance = math.sqrt(nearestDistSq);
    if (distance > _wetBleedRadius) return pigment.color;
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

/// Per-brush-type tuning table. Private to the engine — callers
/// don't need to know about it.
class _BrushTuning {
  const _BrushTuning({
    required this.radius,
    required this.samples,
    required this.spreadX,
    required this.spreadY,
    required this.subAlpha,
  });

  /// Multiplier on the base radius for both the center and sub stamps.
  final double radius;

  /// Multiplier on the bleed sub-stamp count.
  final double samples;

  /// Horizontal / vertical stretch of the sub-stamp cloud. Flat
  /// brushes get spreadX > spreadY to look like a horizontal streak.
  final double spreadX;
  final double spreadY;

  /// Multiplier on the alpha of each sub-stamp. Lower for fan/mop
  /// (softer edges), higher for round/flat (crisper deposits).
  final double subAlpha;
}
