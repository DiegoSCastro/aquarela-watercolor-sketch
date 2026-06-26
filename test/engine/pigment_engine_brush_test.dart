import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment_engine.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PigmentEngine — per-shape stamp strategies', () {
    final ultramar = Pigment.ultramar;

    // A path going east, with enough waypoints for the engine to
    // compute a stable heading for flat/fan brushes.
    final eastPath = <Offset>[
      const Offset(0, 50),
      const Offset(10, 50),
      const Offset(20, 50),
      const Offset(30, 50),
    ];

    Brush brush(BrushType type, {double water = 0.6, double size = 10}) =>
        Brush(
          id: 'b',
          type: type,
          size: size,
          opacity: 0.85,
          waterRatio: water,
        );

    test('round brush emits center disc + circular halo (shape=round)', () {
      final stamps = PigmentEngine.stroke(
        brush: brush(BrushType.round),
        pigment: ultramar,
        path: eastPath,
        existing: const [],
      );

      // The first stamp is the center disc — round shape.
      expect(stamps.first.shape, StampShape.round);
      // Every stamp is a round stamp.
      expect(stamps.every((s) => s.shape == StampShape.round), isTrue);
      // Round stamps have aspectRatio 1 (no elongation).
      expect(stamps.every((s) => s.aspectRatio == 1.0), isTrue);
    });

    test('flat brush emits oriented ovals (shape=oval, aspectRatio > 1)', () {
      final stamps = PigmentEngine.stroke(
        brush: brush(BrushType.flat),
        pigment: ultramar,
        path: eastPath,
        existing: const [],
      );

      // At least one stamp is an oval — the main flat stamp.
      final ovals = stamps.where((s) => s.shape == StampShape.oval).toList();
      expect(ovals, isNotEmpty);
      // Every oval has aspectRatio > 1 (stretched along heading).
      expect(ovals.every((s) => s.aspectRatio > 1.0), isTrue);
      // Aspect ratio for the main stamp should be the configured
      // 3.0 — way bigger than the 1.0 a round brush would emit.
      expect(ovals.first.aspectRatio, greaterThanOrEqualTo(2.5));
      // All ovals carry a non-zero angle (heading of the stroke).
      // East path → angle ≈ 0 (radians).
      for (final oval in ovals) {
        expect(oval.angle.abs(), lessThan(0.2));
      }
    });

    test('flat brush angle tracks stroke heading (rotate 90° = south)', () {
      // Vertical path going south.
      final southPath = <Offset>[
        const Offset(50, 0),
        const Offset(50, 10),
        const Offset(50, 20),
        const Offset(50, 30),
      ];
      final stamps = PigmentEngine.stroke(
        brush: brush(BrushType.flat),
        pigment: ultramar,
        path: southPath,
        existing: const [],
      );
      final ovals = stamps.where((s) => s.shape == StampShape.oval).toList();
      expect(ovals, isNotEmpty);
      // South = atan2(1, 0) = π/2 ≈ 1.5708 rad. The first oval's
      // angle should be close to π/2 (within 0.2 rad tolerance for
      // path discretization).
      expect(ovals.first.angle, closeTo(1.5708, 0.2));
    });

    test('fan brush emits multiple tines with non-zero spread', () {
      final stamps = PigmentEngine.stroke(
        brush: brush(BrushType.fan),
        pigment: ultramar,
        path: eastPath,
        existing: const [],
      );

      final tines = stamps.where((s) => s.shape == StampShape.fan).toList();
      // A fan emits several tines — at least 3 (config has 6 but
      // 15% are dropped, so we expect ~5).
      expect(tines.length, greaterThanOrEqualTo(3));
      // Tines share the same heading (east → angle ≈ 0).
      for (final t in tines) {
        expect(t.angle.abs(), lessThan(0.2));
      }
      // Tines are spread perpendicular to heading — different
      // offsets in Y (perpendicular to east).
      final tineYs = tines.map((t) => t.offset.dy).toList();
      expect(tineYs.toSet().length, greaterThan(1),
          reason: 'tines must be at distinct Y positions');
    });

    test('mop brush emits edge-jittered main stamp + halo', () {
      final stamps = PigmentEngine.stroke(
        brush: brush(BrushType.mop),
        pigment: ultramar,
        path: eastPath,
        existing: const [],
      );

      // First stamp is the main mop disc — irregular shape.
      expect(stamps.first.shape, StampShape.mop);
      // It has non-zero edge jitter.
      expect(stamps.first.edgeJitter, greaterThan(0.0));
      // It's a bigger disc than a round brush at the same size.
      final roundStamps = PigmentEngine.stroke(
        brush: brush(BrushType.round),
        pigment: ultramar,
        path: eastPath,
        existing: const [],
      );
      expect(stamps.first.radius, greaterThan(roundStamps.first.radius));
      // Mop halo uses round sub-stamps.
      final haloRounds =
          stamps.skip(1).where((s) => s.shape == StampShape.round).toList();
      expect(haloRounds, isNotEmpty);
    });

    test('fan tines and oval stamps are NOT emitted by round brush', () {
      final stamps = PigmentEngine.stroke(
        brush: brush(BrushType.round),
        pigment: ultramar,
        path: eastPath,
        existing: const [],
      );
      // No fan or oval stamps in a round stroke.
      expect(stamps.any((s) => s.shape == StampShape.fan), isFalse);
      expect(stamps.any((s) => s.shape == StampShape.oval), isFalse);
      expect(stamps.any((s) => s.shape == StampShape.mop), isFalse);
    });

    test('all brushes produce stamps whose shape is consistent', () {
      // Across a horizontal stroke, each brush's first stamp
      // should carry the *expected* shape — this is the actual
      // visual difference users see.
      final expectations = <BrushType, StampShape>{
        BrushType.round: StampShape.round,
        BrushType.flat: StampShape.oval,
        BrushType.fan: StampShape.fan,
        BrushType.mop: StampShape.mop,
      };
      for (final entry in expectations.entries) {
        final stamps = PigmentEngine.stroke(
          brush: brush(entry.key),
          pigment: ultramar,
          path: eastPath,
          existing: const [],
        );
        expect(
          stamps.first.shape,
          entry.value,
          reason:
              '${entry.key} brush must emit a ${entry.value} as its first stamp',
        );
      }
    });
  });

  group('PigmentEngine.stamp — real-time single waypoint', () {
    final ultramar = Pigment.ultramar;
    final brush = const Brush(
      id: 'round_medium',
      type: BrushType.round,
      size: 16,
      opacity: 0.85,
      waterRatio: 0.5,
    );

    test('emits stamps for a single waypoint (no previous)', () {
      final stamps = PigmentEngine.stamp(
        brush: brush,
        pigment: ultramar,
        point: Offset.zero,
        previousPoint: null,
        existing: const [],
      );
      expect(stamps.length, greaterThanOrEqualTo(1));
    });

    test('emits stamps for a single waypoint with previous heading', () {
      final stamps = PigmentEngine.stamp(
        brush: brush,
        pigment: ultramar,
        point: const Offset(10, 0),
        previousPoint: Offset.zero,
        existing: const [],
      );
      expect(stamps.length, greaterThanOrEqualTo(1));
    });

    test('flat stamp orients toward the previous waypoint', () {
      final flatBrush = const Brush(
        id: 'flat',
        type: BrushType.flat,
        size: 16,
        opacity: 0.85,
        waterRatio: 0.5,
      );
      // Going east (dx > 0, dy = 0) → angle 0.
      final east = PigmentEngine.stamp(
        brush: flatBrush,
        pigment: ultramar,
        point: const Offset(10, 0),
        previousPoint: Offset.zero,
        existing: const [],
      );
      final ovals = east.where((s) => s.shape == StampShape.oval).toList();
      expect(ovals, isNotEmpty);
      expect(ovals.first.angle, closeTo(0.0, 0.1));

      // Going south (dx = 0, dy > 0) → angle π/2.
      final south = PigmentEngine.stamp(
        brush: flatBrush,
        pigment: ultramar,
        point: const Offset(0, 10),
        previousPoint: Offset.zero,
        existing: const [],
      );
      final southOvals =
          south.where((s) => s.shape == StampShape.oval).toList();
      expect(southOvals, isNotEmpty);
      expect(southOvals.first.angle, closeTo(1.5708, 0.1));
    });

    test('can mix with stamps from the same stroke', () {
      final first = PigmentEngine.stamp(
        brush: brush,
        pigment: ultramar,
        point: Offset.zero,
        previousPoint: null,
        existing: const [],
      );
      final synthetic = Stroke(
        id: '__live__',
        brush: brush,
        pigment: PigmentId.ultramar,
        path: <Offset>[Offset.zero],
        stamps: first,
        createdAt: null,
      );
      final second = PigmentEngine.stamp(
        brush: brush,
        pigment: ultramar,
        point: const Offset(3, 3),
        previousPoint: Offset.zero,
        existing: [synthetic],
      );
      expect(second, isNotEmpty);
      // Same color = no shift from wet-on-wet with itself.
      expect(second.first.color.toARGB32(), ultramar.color.toARGB32());
    });
  });
}
