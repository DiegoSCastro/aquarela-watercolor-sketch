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
/// Two effects drive the look:
/// 1. **Path stamps** — one stamp per waypoint, radius = brush.size
/// 2. **Radial bleed** — waterRatio amplifies the stamp radius and
///    adds N sub-stamps with random offsets for organic edges
///
/// Wet-on-wet bleeding (PR 2.1) will extend this; v1 just emits the
/// per-stroke stamps and ignores existing strokes.
class PigmentEngine {
  const PigmentEngine._();

  /// Maximum number of sub-stamps emitted per waypoint for the
  /// radial bleed effect. Tuned to 5 — enough to look organic,
  /// cheap enough to not stutter on a real finger drag.
  static const int _bleedSamples = 5;

  /// Convert a [path] of touch points into renderable stamps.
  ///
  /// [brush] — the active brush (size, opacity, water ratio).
  /// [pigment] — the active pigment (color, absorption).
  /// [path] — finger waypoints. Empty list returns empty list.
  /// [existing] — strokes already on the canvas. v1 ignores them;
  ///   wet-on-wet (PR 2.1) will use this.
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

      // Center stamp (always full size, no jitter).
      stamps.add(Stamp(
        offset: p,
        radius: baseRadius,
        color: pigment.color,
        alpha: brush.opacity,
      ));

      // Bleed sub-stamps: small offsets and slightly different
      // radii, for organic edges. Number of sub-stamps scales with
      // waterRatio: dry=0, wet=5.
      final samples = (brush.waterRatio * _bleedSamples).round();
      for (var s = 0; s < samples; s++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = baseRadius * (0.5 + random.nextDouble() * 0.5);
        final dx = math.cos(angle) * distance;
        final dy = math.sin(angle) * distance;
        final subRadius = baseRadius * (0.3 + random.nextDouble() * 0.4);
        final subAlpha = brush.opacity * (0.3 + random.nextDouble() * 0.4);

        stamps.add(Stamp(
          offset: p + Offset(dx, dy),
          radius: subRadius,
          color: pigment.color,
          alpha: subAlpha,
        ));
      }
    }

    return stamps;
  }
}
