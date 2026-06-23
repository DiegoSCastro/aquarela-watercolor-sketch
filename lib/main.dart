import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/features/home/home_placeholder.dart';
import 'package:aquarela_watercolor_sketch/features/onboarding/onboarding_screen.dart';
import 'package:aquarela_watercolor_sketch/features/paywall/paywall_screen.dart';
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

/// Routes between onboarding, paywall, and home based on
/// [PremiumConfig.current] and the [kStartAt] build-time override.
/// In a future PR this becomes persistent (a SharedPreferences flag
/// for "has finished onboarding" and a billing-driven premium flag);
/// for now it's read at startup.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    // Premium testers skip onboarding + paywall entirely.
    if (kIsPremium) return const HomePlaceholder();

    // QA-only start-at override.
    switch (kStartAt) {
      case 'home':
        return const HomePlaceholder();
      case 'paywall':
        return PaywallScreen(
          onClose: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const HomePlaceholder()),
            );
          },
        );
      case 'onboarding':
      default:
        return const OnboardingScreen();
    }
  }
}

/// Helper used by the onboarding CTA to push the paywall (or
/// home, for premium testers) without leaking Navigator calls.
void navigateAfterOnboarding(BuildContext context) {
  final config = PremiumConfig.current;
  if (config.isPremium) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePlaceholder()),
    );
    return;
  }
  // Free users see the paywall but can dismiss it via the
  // "Continuar no Free" button at the bottom.
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaywallScreen(
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const HomePlaceholder()),
          );
        },
        onPurchaseSuccess: () {
          // PR 4.x: re-read tier from billing here. For now, no-op.
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
