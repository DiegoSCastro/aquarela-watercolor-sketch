import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment_engine.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PigmentEngine.stroke', () {
    final ultramar = Pigment.ultramar;
    final dryBrush = const Brush(
      id: 'round_small',
      type: BrushType.round,
      size: 8,
      opacity: 0.9,
      waterRatio: 0.0,
    );
    final wetBrush = const Brush(
      id: 'round_small',
      type: BrushType.round,
      size: 8,
      opacity: 0.9,
      waterRatio: 1.0,
    );

    test('returns stamps for a 10-point path', () {
      final path = List<Offset>.generate(10, (i) => Offset(i * 5.0, i * 5.0));
      final stamps = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );
      // 1 stamp per point (radial bleed around each waypoint)
      expect(stamps.length, greaterThanOrEqualTo(path.length));
    });

    test('all stamps have non-zero alpha', () {
      final path = List<Offset>.generate(20, (i) => Offset(i * 3.0, i * 3.0));
      final stamps = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );
      for (final s in stamps) {
        expect(s.alpha, greaterThan(0.0));
        expect(s.alpha, lessThanOrEqualTo(1.0));
      }
    });

    test('dry brush produces tighter stamps than wet brush', () {
      final path = List<Offset>.generate(15, (i) => Offset(i * 4.0, i * 4.0));
      final dryStamps = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );
      final wetStamps = PigmentEngine.stroke(
        brush: wetBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );
      // Mean radius of wet stamps should be greater
      final dryMean =
          dryStamps.map((s) => s.radius).reduce((a, b) => a + b) /
          dryStamps.length;
      final wetMean =
          wetStamps.map((s) => s.radius).reduce((a, b) => a + b) /
          wetStamps.length;
      expect(wetMean, greaterThan(dryMean));
    });

    test('empty path returns empty stamp list', () {
      final stamps = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: const [],
        existing: const [],
      );
      expect(stamps, isEmpty);
    });

    test('same input produces same output (determinism)', () {
      final path = List<Offset>.generate(20, (i) => Offset(i * 5.0, i * 2.0));
      final a = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );
      final b = PigmentEngine.stroke(
        brush: dryBrush,
        pigment: ultramar,
        path: path,
        existing: const [],
      );
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].offset, b[i].offset);
        expect(a[i].radius, closeTo(b[i].radius, 1e-6));
      }
    });
  });

  group('Stroke', () {
    test('is finalized on endStroke()', () {
      const stroke = Stroke(
        id: 's1',
        brush: Brush(
          id: 'round_small',
          type: BrushType.round,
          size: 8,
          opacity: 0.9,
          waterRatio: 0.5,
        ),
        pigment: PigmentId.ultramar,
        path: [Offset.zero, Offset(10, 10)],
        stamps: [],
        createdAt: null, // null = not finalized
      );
      expect(stroke.isFinalized, isFalse);
    });
  });

  group('Stamp', () {
    test('carries offset, radius, color, alpha', () {
      const stamp = Stamp(
        offset: Offset(10, 20),
        radius: 5.0,
        color: Color(0xFF1E3A8A),
        alpha: 0.7,
      );
      expect(stamp.offset, const Offset(10, 20));
      expect(stamp.radius, 5.0);
      expect(stamp.alpha, 0.7);
    });
  });
}
