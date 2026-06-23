import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumConfig (free tier)', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: false));
    tearDown(PremiumConfig.resetForTest);

    test('maxPigments is 4 (brand colors only)', () {
      expect(PremiumConfig.current.maxPigments, 4);
    });

    test('availableBrushes contains only roundSmall', () {
      expect(PremiumConfig.current.availableBrushes, [BrushId.roundSmall]);
    });

    test('maxSavedPaintings is 3', () {
      expect(PremiumConfig.current.maxSavedPaintings, 3);
    });

    test('maxSessionSeconds is 30', () {
      expect(PremiumConfig.current.maxSessionSeconds, 30);
    });

    test('exportWatermark is true', () {
      expect(PremiumConfig.current.exportWatermark, isTrue);
    });

    test('maxExportPx is 1024', () {
      expect(PremiumConfig.current.maxExportPx, 1024);
    });

    test('showAds is true', () {
      expect(PremiumConfig.current.showAds, isTrue);
    });

    test('lockedPigments is the last 8 of the 12-pigment palette', () {
      expect(
        PremiumConfig.current.lockedPigments,
        PigmentId.values.sublist(4),
      );
    });

    test('lockedBrushes is everything except roundSmall', () {
      expect(
        PremiumConfig.current.lockedBrushes,
        BrushId.values.sublist(1),
      );
    });

    test('tierName is Free', () {
      expect(PremiumConfig.current.tierName, 'Free');
    });
  });

  group('PremiumConfig (pro tier)', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: true));
    tearDown(PremiumConfig.resetForTest);

    test('maxPigments is 12 (full palette)', () {
      expect(PremiumConfig.current.maxPigments, 12);
    });

    test('availableBrushes contains all 6 brushes', () {
      expect(PremiumConfig.current.availableBrushes, BrushId.values);
    });

    test('maxSavedPaintings is unlimited (-1)', () {
      expect(PremiumConfig.current.maxSavedPaintings, -1);
    });

    test('maxSessionSeconds is unlimited (-1)', () {
      expect(PremiumConfig.current.maxSessionSeconds, -1);
    });

    test('exportWatermark is false', () {
      expect(PremiumConfig.current.exportWatermark, isFalse);
    });

    test('maxExportPx is 4096', () {
      expect(PremiumConfig.current.maxExportPx, 4096);
    });

    test('showAds is false', () {
      expect(PremiumConfig.current.showAds, isFalse);
    });

    test('lockedPigments is empty', () {
      expect(PremiumConfig.current.lockedPigments, isEmpty);
    });

    test('lockedBrushes is empty', () {
      expect(PremiumConfig.current.lockedBrushes, isEmpty);
    });

    test('tierName is Pro', () {
      expect(PremiumConfig.current.tierName, 'Pro');
    });
  });
}
