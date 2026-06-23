import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment_engine.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

void main() {
  group('PigmentEngine.stroke — wet-on-wet bleeding', () {
    final wetBrush = const Brush(
      id: 'round_small',
      type: BrushType.round,
      size: 12,
      opacity: 0.85,
      waterRatio: 0.8,
    );
    final dryBrush = const Brush(
      id: 'round_small',
      type: BrushType.round,
      size: 12,
      opacity: 0.85,
      waterRatio: 0.0,
    );
    final ultramar = Pigment.ultramar;
    final viridian = Pigment.viridian;
    final viridianColor = viridian.color;

    Offset point(double x, double y) => Offset(x, y);

    Stroke strokeWithStamps(List<Stamp> stamps, {String id = 's0'}) {
      return Stroke(
        id: id,
        brush: wetBrush,
        pigment: ultramar.id,
        path: [point(0, 0)],
        stamps: stamps,
        createdAt: DateTime.now(),
      );
    }

    Stamp stampAt(Offset offset, {Color? color, double radius = 10}) {
      return Stamp(
        offset: offset,
        radius: radius,
        color: color ?? ultramar.color,
        alpha: 0.85,
      );
    }

    test('dry brush does not mix with nearby stroke', () {
      final path = [point(0, 0)];
      final existing = [
        strokeWithStamps([stampAt(point(10, 10), color: viridianColor)]),
      ];

      final stamps = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: path,
        existing: existing,
      );

      // The center stamp should remain pure ultramar — no mix.
      expect(stamps.first.color, ultramar.color);
    });

    test('wet brush mixes with nearby existing stroke', () {
      final path = [point(0, 0)];
      final existing = [
        strokeWithStamps([stampAt(point(10, 10), color: viridianColor)]),
      ];

      final stamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: existing,
      );

      // The center stamp should now be a mix between ultramar and
      // viridian — neither pure ultramar nor pure viridian.
      final mixed = stamps.first.color;
      expect(mixed, isNot(equals(ultramar.color)));
      expect(mixed, isNot(equals(viridianColor)));
    });

    test('wet brush far from any stroke does not mix', () {
      // Existing stroke is 1000px away — well outside bleed radius.
      final path = [point(0, 0)];
      final existing = [
        strokeWithStamps([stampAt(point(1000, 1000), color: viridianColor)]),
      ];

      final stamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: existing,
      );

      expect(stamps.first.color, ultramar.color);
    });

    test('mix strength scales with proximity', () {
      // Each waypoint gets its own existing stroke at a different
      // distance — closer existing = stronger mix toward viridian.
      final closeExisting = [
        strokeWithStamps([stampAt(point(10, 0), color: viridianColor)]),
      ];
      final farExisting = [
        strokeWithStamps([stampAt(point(100, 0), color: viridianColor)]),
      ];
      final path = [point(0, 0)];

      final closeStamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: closeExisting,
      );
      final farStamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: farExisting,
      );

      // Closer existing stamp = more viridian in the mix.
      final closeViridianness = _distanceFromViridian(closeStamps.first.color);
      final farViridianness = _distanceFromViridian(farStamps.first.color);
      expect(closeViridianness, lessThan(farViridianness));
    });

    test('mix is biased toward the pigment when brush is moderately wet', () {
      // WaterRatio 0.3 — wet enough to mix, but mixAmount capped.
      final slightlyWet = const Brush(
        id: 'round_small',
        type: BrushType.round,
        size: 12,
        opacity: 0.85,
        waterRatio: 0.3,
      );
      final veryWet = const Brush(
        id: 'round_small',
        type: BrushType.round,
        size: 12,
        opacity: 0.85,
        waterRatio: 1.0,
      );
      final existing = [
        strokeWithStamps([stampAt(point(5, 5), color: viridianColor)]),
      ];
      final path = [point(0, 0)];

      final slightlyMixed = PigmentEngine.stroke(
        brush: slightlyWet,
        pigment: ultramar,
        path: path,
        existing: existing,
      );
      final veryMixed = PigmentEngine.stroke(
        brush: veryWet,
        pigment: ultramar,
        path: path,
        existing: existing,
      );

      // Higher waterRatio = closer to viridian.
      final slightViridianness = _distanceFromViridian(
        slightlyMixed.first.color,
      );
      final veryViridianness = _distanceFromViridian(veryMixed.first.color);
      expect(veryViridianness, lessThan(slightViridianness));
    });

    test('empty existing strokes does not crash and returns base color', () {
      final path = [point(0, 0), point(10, 10), point(20, 20)];
      final stamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );

      // No mix target — every stamp should be the base ultramar.
      for (final s in stamps) {
        expect(s.color, ultramar.color);
      }
    });

    test('skips existing strokes that have no stamps yet', () {
      // A stroke with stamps: [] is still being drawn — it
      // shouldn't bleed into itself or into other live strokes.
      final emptyStroke = Stroke(
        id: 'live',
        brush: wetBrush,
        pigment: ultramar.id,
        path: [point(5, 5)],
        stamps: const [],
        createdAt: DateTime.now(),
      );
      final path = [point(0, 0)];
      final stamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: [emptyStroke],
      );

      // Nothing to mix with — pure ultramar.
      expect(stamps.first.color, ultramar.color);
    });
  });
}

/// Helper — distance in RGB space from pure viridian. Lower =
/// closer to viridian. Used to compare "how mixed" a stamp got
/// without having to recreate the exact lerp math.
double _distanceFromViridian(Color c) {
  final target = Pigment.viridian.color;
  final dr = (c.r - target.r).abs();
  final dg = (c.g - target.g).abs();
  final db = (c.b - target.b).abs();
  return dr + dg + db;
}
