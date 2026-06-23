import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pigment', () {
    test('ultramar has the brand hex #1E3A8A', () {
      expect(Pigment.ultramar.color.toARGB32(), 0xFF1E3A8A);
    });

    test('all curated pigments have valid ARGB color', () {
      for (final p in Pigment.curated) {
        // toARGB32 returns 0xAARRGGBB, must be non-zero alpha
        expect(p.color.toARGB32() & 0xFF000000, 0xFF000000,
            reason: '${p.name} must have full alpha');
      }
    });

    test('all curated pigments have non-empty name', () {
      for (final p in Pigment.curated) {
        expect(p.name.isNotEmpty, isTrue, reason: 'Pigment ${p.id} missing name');
      }
    });

    test('absorption is in [0..1] for all pigments', () {
      for (final p in Pigment.curated) {
        expect(p.absorption, inInclusiveRange(0.0, 1.0));
        expect(p.granulation, inInclusiveRange(0.0, 1.0));
      }
    });

    test('darker pigments have higher absorption than lighter ones', () {
      // Cadmium yellow (light) should absorb less than paynes gray (dark)
      final cadmium = Pigment.curated.firstWhere((p) => p.id == 'cadmium_yellow');
      final paynes = Pigment.curated.firstWhere((p) => p.id == 'paynes_gray');
      expect(paynes.absorption, greaterThan(cadmium.absorption));
    });
  });
}
