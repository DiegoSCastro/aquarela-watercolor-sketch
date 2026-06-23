import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
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
      final cadmium = Pigment.curated
          .firstWhere((p) => p.id == PigmentId.cadmiumYellow);
      final paynes = Pigment.curated
          .firstWhere((p) => p.id == PigmentId.paynesGray);
      expect(paynes.absorption, greaterThan(cadmium.absorption));
    });

    test('exactly 12 curated pigments', () {
      expect(Pigment.curated.length, 12);
      expect(PigmentId.values.length, 12);
    });

    test('every PigmentId has a matching Pigment entry', () {
      // Defensive: if a new PigmentId is added without a Pigment, this fails
      for (final id in PigmentId.values) {
        final p = Pigment.byId(id);
        expect(p, isNotNull, reason: 'No Pigment for $id');
        expect(p!.id, id);
      }
    });

    test('first 4 pigments are the brand (free) set', () {
      expect(Pigment.curated[0].id, PigmentId.ultramar);
      expect(Pigment.curated[1].id, PigmentId.burntSienna);
      expect(Pigment.curated[2].id, PigmentId.cadmiumYellow);
      expect(Pigment.curated[3].id, PigmentId.paynesGray);
    });

    test('granulation pigments are burntSienna, viridian, cerulean, sepia', () {
      final granulating = Pigment.curated
          .where((p) => p.granulation > 0)
          .map((p) => p.id)
          .toSet();
      expect(granulating, containsAll([
        PigmentId.burntSienna,
        PigmentId.viridian,
        PigmentId.cerulean,
        PigmentId.sepia,
      ]));
    });

    test('lightest pigment is lemon yellow (lowest absorption)', () {
      final lightest = Pigment.curated.reduce(
        (a, b) => a.absorption < b.absorption ? a : b,
      );
      expect(lightest.id, PigmentId.lemonYellow);
    });
  });
}
