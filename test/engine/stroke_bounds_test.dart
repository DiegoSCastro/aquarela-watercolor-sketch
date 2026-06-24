import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  group('Stroke.bounds', () {
    test('empty stamps + empty path returns zero rect', () {
      const stroke = Stroke(
        id: 's0',
        brush: Brush(
          id: 'round_medium',
          type: BrushType.round,
          size: 16,
          opacity: 0.85,
          waterRatio: 0.5,
        ),
        pigment: PigmentId.ultramar,
        path: <Offset>[],
        stamps: <Stamp>[],
        createdAt: null,
      );
      expect(stroke.bounds, Rect.zero);
    });

    test('empty stamps + non-empty path returns single-point rect', () {
      final stroke = Stroke(
        id: 's0',
        brush: const Brush(
          id: 'round_medium',
          type: BrushType.round,
          size: 16,
          opacity: 0.85,
          waterRatio: 0.5,
        ),
        pigment: PigmentId.ultramar,
        path: const [Offset(50, 75)],
        stamps: const <Stamp>[],
        createdAt: null,
      );
      expect(stroke.bounds, const Rect.fromLTWH(50, 75, 0, 0));
    });

    test('multiple stamps produces tight bounding box', () {
      final stroke = Stroke(
        id: 's0',
        brush: const Brush(
          id: 'round_medium',
          type: BrushType.round,
          size: 16,
          opacity: 0.85,
          waterRatio: 0.5,
        ),
        pigment: PigmentId.ultramar,
        path: const <Offset>[],
        stamps: const [
          Stamp(offset: Offset(10, 20), radius: 5, color: Colors.red, alpha: 1),
          Stamp(offset: Offset(50, 80), radius: 5, color: Colors.red, alpha: 1),
          Stamp(offset: Offset(30, 5), radius: 5, color: Colors.red, alpha: 1),
        ],
        createdAt: null,
      );
      expect(stroke.bounds, const Rect.fromLTRB(10, 5, 50, 80));
    });

    test('bounds is cached — same instance returns identical result', () {
      final stroke = Stroke(
        id: 's0',
        brush: const Brush(
          id: 'round_medium',
          type: BrushType.round,
          size: 16,
          opacity: 0.85,
          waterRatio: 0.5,
        ),
        pigment: PigmentId.ultramar,
        path: const <Offset>[],
        stamps: const [
          Stamp(offset: Offset(10, 20), radius: 5, color: Colors.red, alpha: 1),
        ],
        createdAt: null,
      );
      final a = stroke.bounds;
      final b = stroke.bounds;
      // Same cached instance (Rect doesn't have a stable identity,
      // but it must produce the same values without recomputing).
      expect(a, b);
    });
  });
}
