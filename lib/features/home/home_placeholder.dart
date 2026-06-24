import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/ads/banner_ad_widget.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_screen.dart';
import 'package:aquarela_watercolor_sketch/features/gallery/gallery_screen.dart';
import 'package:aquarela_watercolor_sketch/theme/components/pigment_button.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Landing screen after onboarding. Greets the painter, links to
/// the gallery, and has a big primary CTA to start painting.
///
/// The app is free with ads — no tier system, no paywall, no
/// limits beyond the gesture surface itself.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paper.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Space.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Greeting(),
                  const _SettingsButton(),
                ],
              ),
              const SizedBox(height: Space.xl),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IntroCard(),
                      SizedBox(height: Space.md),
                      GalleryEntryButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              PigmentButton(
                label: 'Começar a pintar',
                icon: Icons.brush_outlined,
                expand: true,
                onPressed: () => _openCanvas(context),
              ),
              const SizedBox(height: Space.lg),
              const BannerAdWidget(),
              const SizedBox(height: Space.sm),
            ],
          ),
        ),
      ),
    );
  }

  static void _openCanvas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CanvasScreen(),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, pintor',
          style: AquarelaTypography.headlineLarge.copyWith(
            color: Paper.ink,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: BrandPigment.cadmiumYellow.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(RadiusToken.full),
          ),
          child: Text(
            'Aquarela',
            style: AquarelaTypography.caption.copyWith(
              color: Paper.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings is a no-op in v1 — the app has no settings screen yet.
/// The button stays visible so the layout is final, and the
/// disabled state signals "coming soon" without a misleading CTA.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_rounded, color: Paper.charcoal),
      tooltip: 'Configurações (em breve)',
      onPressed: () => _showComingSoon(context),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações chegando em breve'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// A short marketing card that explains what the app is and what
/// makes it different: minimal, watercolor-only, free with ads.
class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: Paper.cream,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: Paper.mist.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pinte com aquarela',
            style: AquarelaTypography.headlineSmall.copyWith(
              color: Paper.ink,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Toque e arraste — a tinta escorre, mistura e seca como '
            'numa folha de papel de verdade. Sem limites de sessão, '
            'sem assinatura.',
            style: AquarelaTypography.bodyMedium.copyWith(
              color: Paper.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone gallery entry (no longer pushed by the home button;
/// used as a target by deep links and onboarding in future PRs).
class GalleryEntryButton extends StatelessWidget {
  const GalleryEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PigmentButton(
      label: 'Ver galeria',
      icon: Icons.photo_library_outlined,
      variant: PigmentButtonVariant.ghost,
      expand: true,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const GalleryScreen(),
          ),
        );
      },
    );
  }
}
