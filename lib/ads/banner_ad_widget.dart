import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:aquarela_watercolor_sketch/ads/ad_service.dart';

/// A platform-aware banner ad widget. Shows a 320x50 banner that
/// refreshes on its own. Renders nothing if ads fail to load —
/// the app stays usable in the (rare) case AdMob is unreachable.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = AdService.createBanner()
      ..load().then((_) {
        if (mounted) setState(() => _loaded = true);
      }).catchError((Object _) {
        if (mounted) setState(() => _loaded = false);
      });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: AdWidget(ad: _ad!),
    );
  }
}
