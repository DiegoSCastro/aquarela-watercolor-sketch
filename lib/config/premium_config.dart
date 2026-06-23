/// Aquarela premium config — the single source of truth for tier behavior.
///
/// Override the [kIsPremium] flag at build time:
///   flutter run --dart-define=PREMIUM=true
///   flutter build apk --dart-define=PREMIUM=true
///
/// In tests:
///   PremiumConfig.overrideForTest(isPremium: true);
///   addTearDown(PremiumConfig.resetForTest);
///
/// All other code reads [PremiumConfig.current] — never [kIsPremium]
/// directly — so tests can flip the tier without rebuilding.
library;

import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';

export 'package:aquarela_watercolor_sketch/config/palette_ids.dart'
    show BrushId, PigmentId;

/// Build-time premium flag. Defaults to free so the open-source build
/// is always a free build, and so a developer who forgets the
/// `--dart-define` doesn't accidentally ship a Pro build.
const bool kIsPremium = bool.fromEnvironment(
  'PREMIUM',
  defaultValue: false,
);

/// Build-time deep-link for QA: forces the app to launch into a
/// specific screen, bypassing the normal flow. Values:
///   onboarding (default)  — show onboarding, then paywall on finish
///   home                  — skip onboarding, go straight to home
///   paywall               — skip onboarding, go straight to paywall
///
/// Example:
///   flutter run --dart-define=START_AT=paywall
const String kStartAt = String.fromEnvironment(
  'START_AT',
  defaultValue: 'onboarding',
);

/// Tier-specific limits. Read via [PremiumConfig.current].
class PremiumConfig {
  const PremiumConfig._({required this.isPremium});

  /// The current tier config. Initialized to the build-time [kIsPremium].
  static PremiumConfig current = PremiumConfig._(isPremium: kIsPremium);

  /// True if the running build is Pro. UI components branch on this
  /// (lock badges, banners, paywall routing).
  final bool isPremium;

  // ---------- Tier limits ----------
  //
  // Constants live here so the rest of the app reads them from
  // [current] without scattering magic numbers. Bumping the Pro
  // caps only takes editing this file.

  /// Free tier pigment count. Pro = all 12.
  static const int _freePigmentCount = 4;

  /// Free tier brush count (just roundSmall). Pro = all 6.
  static const int _freeBrushCount = 1;

  /// Free tier gallery capacity. Pro = unlimited (-1).
  static const int _freeMaxSavedPaintings = 3;

  /// Free tier session length (seconds). Pro = unlimited (-1).
  static const int _freeMaxSessionSeconds = 30;

  /// Free tier export resolution (longest side, px). Pro = 4096.
  static const int _freeMaxExportPx = 1024;

  /// Maximum number of pigments the user can pick from the palette.
  /// Free: 4 brand colors. Pro: all 12.
  int get maxPigments => isPremium ? PigmentId.values.length : _freePigmentCount;

  /// Brushes available to the tier. Free: round small only. Pro: all 6.
  List<BrushId> get availableBrushes => isPremium
      ? BrushId.values
      : BrushId.values.sublist(0, _freeBrushCount);

  /// How many saved paintings the gallery can hold. Free: 3, Pro: unlimited.
  int get maxSavedPaintings =>
      isPremium ? -1 : _freeMaxSavedPaintings;

  /// Maximum session length in seconds. Free: 30s, Pro: unlimited (-1).
  int get maxSessionSeconds => isPremium ? -1 : _freeMaxSessionSeconds;

  /// Whether the PNG export carries a watermark. Pro: clean export.
  bool get exportWatermark => !isPremium;

  /// Maximum export resolution (longest side, px). Free: 1024, Pro: 4096.
  int get maxExportPx => isPremium ? 4096 : _freeMaxExportPx;

  /// Whether the AdMob banner is shown. Pro: ad-free.
  bool get showAds => !isPremium;

  /// Pro-only pigment IDs. Free users see a lock badge on these.
  List<PigmentId> get lockedPigments =>
      isPremium ? const [] : PigmentId.values.sublist(maxPigments);

  /// Pro-only brush IDs. Free users see a lock badge on these.
  List<BrushId> get lockedBrushes =>
      isPremium ? const [] : BrushId.values.sublist(_freeBrushCount);

  /// Human-readable tier name for UI.
  String get tierName => isPremium ? 'Pro' : 'Free';

  // ---------- Test hooks ----------

  /// Test-only: swap [current] for a synthetic config.
  static void overrideForTest({required bool isPremium}) {
    current = PremiumConfig._(isPremium: isPremium);
  }

  /// Test-only: restore [current] to the build-time default.
  static void resetForTest() {
    current = PremiumConfig._(isPremium: kIsPremium);
  }
}
