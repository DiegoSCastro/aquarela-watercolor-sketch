import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob wrapper. Initialises the SDK once and exposes a banner
/// factory. The app uses banners only — no interstitials, no
/// rewarded — to keep the experience uninterrupted while painting.
///
/// Ad unit IDs are read from build-time defines so the same binary
/// can run against test or production by changing the build flags:
///   --dart-define=ADMOB_APP_ID=ca-app-pub-...
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-...
///
/// If the defines are missing we fall back to Google's official
/// sample IDs (safe for development, never serve real ads).
class AdService {
  AdService._();

  static const String _defaultAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String _defaultBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static String get _appId =>
      const String.fromEnvironment('ADMOB_APP_ID', defaultValue: _defaultAppId);

  static String get _bannerId => const String.fromEnvironment(
        'ADMOB_BANNER_ID',
        defaultValue: _defaultBannerId,
      );

  static bool _initialised = false;

  /// Initialise the Google Mobile Ads SDK. Safe to call multiple
  /// times — only the first call does work.
  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    // On non-Android/iOS platforms (desktop, web) the plugin
    // throws on init; swallow so tests / hot reload don't crash.
    try {
      await MobileAds.instance.initialize();
    } on Object catch (e) {
      debugPrint('AdService.init failed: $e');
    }
  }

  /// Build a banner ad sized for the current screen width. The
  /// caller is responsible for placing the returned [BannerAd] in
  /// a widget and calling [BannerAd.dispose] when it goes out of
  /// scope (we hand back a load helper that returns a fresh
  /// [BannerAd] on each call).
  static BannerAd createBanner() {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    );
  }

  /// App ID string used by the Android manifest / iOS Info.plist
  /// injection. Surfaced here for completeness.
  static String get appId => _appId;
}
