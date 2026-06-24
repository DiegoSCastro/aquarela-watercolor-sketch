import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquarela_watercolor_sketch/ads/ad_service.dart';
import 'package:aquarela_watercolor_sketch/features/home/home_placeholder.dart';
import 'package:aquarela_watercolor_sketch/features/onboarding/onboarding_screen.dart';
import 'package:aquarela_watercolor_sketch/theme/aquarela_theme.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Paper.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // Fire and forget — banner loading waits for this in the widget.
  AdService.init();
  runApp(const AquarelaApp());
}

class AquarelaApp extends StatelessWidget {
  const AquarelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquarela',
      debugShowCheckedModeBanner: false,
      theme: AquarelaTheme.light(),
      home: const _RootRouter(),
    );
  }
}

/// Routes between onboarding and home. Onboarding shows once
/// per fresh install; in a future PR this becomes a SharedPreferences
/// flag. For now it always shows on cold start.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen();
  }
}

/// Helper used by the onboarding CTA to push the home screen.
void navigateAfterOnboarding(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => const HomePlaceholder()),
  );
}
