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

/// Pigment identifiers for the curated palette. Kept as a plain enum
/// (not a Color object) so this file stays pure-Dart and testable
/// without Flutter bindings.
enum PigmentId {
  ultramar,
  burntSienna,
  cadmiumYellow,
  paynesGray,
  viridian,
  alizarinCrimson,
  cerulean,
  lemonYellow,
  roseMadder,
  sapGreen,
  indigo,
  sepia,
}

/// Brush identifiers — the round/small brush is the only free one.
enum BrushId {
  roundSmall,
  roundMedium,
  roundLarge,
  flat,
  fan,
  mop,
}

/// Tier-specific limits. Read via [PremiumConfig.current].
class PremiumConfig {
  const PremiumConfig._({required this.isPremium});

  /// The current tier config. Initialized to the build-time [kIsPremium].
  static PremiumConfig current = PremiumConfig._(isPremium: kIsPremium);

  /// True if the running build is Pro. UI components branch on this
  /// (lock badges, banners, paywall routing).
  final bool isPremium;

  /// Maximum number of pigments the user can pick from the palette.
  /// Free: 4 brand colors. Pro: all 12.
  int get maxPigments => isPremium ? 12 : 4;

  /// Brushes available to the tier. Free: round small only. Pro: all 6.
  List<BrushId> get availableBrushes => isPremium
      ? BrushId.values
      : const [BrushId.roundSmall];

  /// How many saved paintings the gallery can hold. Free: 3, Pro: unlimited.
  int get maxSavedPaintings => isPremium ? -1 : 3;

  /// Maximum session length in seconds. Free: 30s, Pro: unlimited (-1).
  int get maxSessionSeconds => isPremium ? -1 : 30;

  /// Whether the PNG export carries a watermark. Pro: clean export.
  bool get exportWatermark => !isPremium;

  /// Maximum export resolution. Free: 1024px, Pro: 4096px.
  int get maxExportPx => isPremium ? 4096 : 1024;

  /// Whether the AdMob banner is shown. Pro: ad-free.
  bool get showAds => !isPremium;

  /// Pro-only pigment IDs. Free users see a lock badge on these.
  List<PigmentId> get lockedPigments => isPremium
      ? const []
      : PigmentId.values.sublist(maxPigments);

  /// Pro-only brush IDs. Free users see a lock badge on these.
  List<BrushId> get lockedBrushes => isPremium
      ? const []
      : BrushId.values.sublist(1);

/// All pigments are usable, regardless of tier. Free users only
  /// see 4 unlocked, but the model is the same.
  List<PigmentId> get allPigments => PigmentId.values;

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
