import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/theme/components/pigment_button.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Paywall — shown after onboarding for free users, and reachable
/// from any upgrade CTA in the app.
///
/// In PR 1.0 (this PR), the buy buttons are stubs. They show a
/// snackbar and do nothing. PR 4.x wires Google Play Billing v6
/// (Android) and StoreKit 2 (iOS) and replaces the stubs with the
/// real purchase flow.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, this.onClose, this.onPurchaseSuccess});

  /// Optional close (X) button. Pass null to hide it (e.g. when
  /// shown right after onboarding — user must choose).
  final VoidCallback? onClose;

  /// Called after a successful purchase (stub for now). The router
  /// pops back to the caller and the next screen reads
  /// [PremiumConfig.current] to know the user is now Pro.
  final VoidCallback? onPurchaseSuccess;

  void _showComingSoon(BuildContext context, String tier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compra do $tier chegando no PR 4.x (Billing)',
          style: AquarelaTypography.bodyMedium.copyWith(color: Paper.white),
        ),
        backgroundColor: Pigment.ultramar,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusToken.md),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paper.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: close (optional)
            if (onClose != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Paper.charcoal,
                      ),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: Space.lg),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Pigment.ultramar.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.brush_rounded,
                        size: 36,
                        color: Pigment.ultramar,
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    Text(
                      'Aquarela Pro',
                      textAlign: TextAlign.center,
                      style: AquarelaTypography.displaySmall.copyWith(
                        color: Paper.ink,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'Todos os pigmentos, pincéis e exportação em alta.',
                      textAlign: TextAlign.center,
                      style: AquarelaTypography.bodyLarge.copyWith(
                        color: Paper.charcoal,
                      ),
                    ),
                    const SizedBox(height: Space.xl),

                    // Tier 1 — Pro (full app)
                    _TierCard(
                      accent: Pigment.ultramar,
                      badge: 'Recomendado',
                      title: 'Pro',
                      price: r'R$ 14,90',
                      priceSuffix: 'pagamento único',
                      features: const [
                        'Todos os 12 pigmentos',
                        '6 pincéis (round, flat, fan, mop)',
                        'Sessões sem limite de tempo',
                        'Galeria ilimitada',
                        'Export em alta (4096px)',
                        'Sem anúncios',
                      ],
                      onChoose: () => _showComingSoon(context, 'Pro'),
                    ),
                    const SizedBox(height: Space.lg),

                    // Tier 2 — Palette Pack (additive, cheaper)
                    _TierCard(
                      accent: Pigment.burntSienna,
                      badge: 'Compacto',
                      title: 'Palette Pack',
                      price: r'R$ 9,90',
                      priceSuffix: 'expansão da paleta',
                      features: const [
                        '12 pigmentos desbloqueados',
                        'Mantém anúncios',
                        'Limite de 3 obras salvas',
                        "Export com marca d'água",
                      ],
                      onChoose: () => _showComingSoon(context, 'Palette Pack'),
                    ),

                    const SizedBox(height: Space.xl),

                    // Restore purchases
                    TextButton(
                      onPressed: () => _showComingSoon(context, 'Restore'),
                      child: Text(
                        'Restaurar compras',
                        style: AquarelaTypography.bodyMedium.copyWith(
                          color: Pigment.ultramar,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                  ],
                ),
              ),
            ),

            // Bottom CTA — Continue free
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.md,
                Space.xl,
                Space.lg,
              ),
              child: PigmentButton(
                label: PremiumConfig.current.isPremium
                    ? 'Já sou Pro'
                    : 'Continuar no Free',
                variant: PigmentButtonVariant.ghost,
                expand: true,
                onPressed: () {
                  if (PremiumConfig.current.isPremium) {
                    onPurchaseSuccess?.call();
                  } else {
                    onClose?.call();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.accent,
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.onChoose,
    this.badge,
  });

  final Color accent;
  final String? badge;
  final String title;
  final String price;
  final String priceSuffix;
  final List<String> features;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: Paper.cream,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Paper.shadow(opacity: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AquarelaTypography.headlineLarge.copyWith(
                  color: Paper.ink,
                  fontSize: 22,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(RadiusToken.full),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Paper.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AquarelaTypography.displayMedium.copyWith(
                  color: Paper.ink,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  priceSuffix,
                  style: AquarelaTypography.bodyMedium.copyWith(
                    color: Paper.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: AquarelaTypography.bodyMedium.copyWith(
                        color: Paper.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          PigmentButton(
            label: 'Escolher $title',
            expand: true,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}
