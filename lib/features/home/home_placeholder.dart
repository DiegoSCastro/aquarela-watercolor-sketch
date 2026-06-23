import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_screen.dart';
import 'package:aquarela_watercolor_sketch/features/paywall/paywall_screen.dart';
import 'package:aquarela_watercolor_sketch/theme/components/lock_badge.dart';
import 'package:aquarela_watercolor_sketch/theme/components/pigment_button.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Placeholder home — shows what the user gets right now (Free tier
/// limits clearly visible) and a CTA to upgrade. Replaced by the
/// canvas screen in PR 1.1.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final config = PremiumConfig.current;
    final isFree = !config.isPremium;

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
                  Column(
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
                          color: isFree
                              ? Paper.cream
                              : BrandPigment.cadmiumYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(RadiusToken.full),
                        ),
                        child: Text(
                          'Plano ${config.tierName}',
                          style: AquarelaTypography.caption.copyWith(
                            color: isFree ? Paper.charcoal : Paper.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Paper.charcoal),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: Space.xl),

              // Upgrade banner — free users only
              if (isFree)
                UpgradeBanner(
                  onUpgrade: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaywallScreen(
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                ),

              if (isFree) const SizedBox(height: Space.xl),

              // Tier summary card
              _TierSummaryCard(),

              const Spacer(),

              PigmentButton(
                label: 'Começar a pintar',
                icon: Icons.brush_outlined,
                expand: true,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CanvasScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: Space.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = PremiumConfig.current;

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
            'Seu plano',
            style: AquarelaTypography.headlineSmall.copyWith(
              color: Paper.ink,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: Space.md),
          _LimitRow(
            icon: Icons.water_drop_outlined,
            label: 'Pigmentos',
            value: config.isPremium
                ? '12 (todos)'
                : '${config.maxPigments} de 12',
            isLocked: !config.isPremium && config.maxPigments < 12,
          ),
          _LimitRow(
            icon: Icons.brush_outlined,
            label: 'Pincéis',
            value: config.isPremium
                ? '6 (todos)'
                : '${config.availableBrushes.length} de 6',
            isLocked: !config.isPremium && config.availableBrushes.length < 6,
          ),
          _LimitRow(
            icon: Icons.timer_outlined,
            label: 'Sessão',
            value: config.isPremium
                ? 'Ilimitada'
                : '${config.maxSessionSeconds}s',
            isLocked: !config.isPremium,
          ),
          _LimitRow(
            icon: Icons.photo_library_outlined,
            label: 'Obras salvas',
            value: config.isPremium
                ? 'Ilimitadas'
                : 'Até ${config.maxSavedPaintings}',
            isLocked: !config.isPremium,
          ),
          _LimitRow(
            icon: Icons.high_quality_outlined,
            label: "Export",
            value: config.isPremium
                ? "${config.maxExportPx}px HD"
                : "${config.maxExportPx}px + marca d'água",
            isLocked: !config.isPremium,
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLocked,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Paper.charcoal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AquarelaTypography.bodyMedium.copyWith(
                color: Paper.charcoal,
              ),
            ),
          ),
          Text(
            value,
            style: AquarelaTypography.bodyMedium.copyWith(
              color: Paper.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isLocked) ...[
            const SizedBox(width: 8),
            const LockBadge(size: 16),
          ],
        ],
      ),
    );
  }
}
