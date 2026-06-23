import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/features/paywall/paywall_screen.dart';
import 'package:aquarela_watercolor_sketch/theme/components/lock_badge.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart'
    show BrandPigment;
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_cubit.dart';

/// Bottom sheet that lets the user pick a pigment and adjust
/// brush settings. Lives inside the canvas sheet — receives the
/// [CanvasCubit] via BlocProvider.value from the parent.
class PaletteScreen extends StatelessWidget {
  const PaletteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: Space.md),
                decoration: BoxDecoration(
                  color: Paper.mist,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pigmentos',
                  style: AquarelaTypography.headlineLarge.copyWith(
                    color: Paper.ink,
                    fontSize: 20,
                  ),
                ),
                _TierBadge(),
              ],
            ),
            const SizedBox(height: Space.md),
            const _SelectedPigmentCard(),
            const SizedBox(height: Space.lg),
            const _PigmentGrid(),
            const SizedBox(height: Space.lg),
            const _BrushControls(),
          ],
        ),
      ),
    );
  }
}

/// Small badge showing the user's current tier (Free / Pro).
class _TierBadge extends StatelessWidget {
  const _TierBadge();

  @override
  Widget build(BuildContext context) {
    final config = PremiumConfig.current;
    final isPro = config.isPremium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPro
            ? BrandPigment.cadmiumYellow.withValues(alpha: 0.2)
            : Paper.cream,
        borderRadius: BorderRadius.circular(RadiusToken.full),
      ),
      child: Text(
        'Plano ${config.tierName}',
        style: AquarelaTypography.caption.copyWith(
          color: isPro ? Paper.ink : Paper.charcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Big card showing the currently selected pigment: name,
/// characteristics, and a large color swatch.
class _SelectedPigmentCard extends StatelessWidget {
  const _SelectedPigmentCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      buildWhen: (a, b) => a.currentPigment != b.currentPigment,
      builder: (context, state) {
        final p = Pigment.byId(state.currentPigment);
        if (p == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: Paper.cream,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
              color: Paper.mist.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: p.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Paper.ink.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Paper.shadow(opacity: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AquarelaTypography.headlineSmall.copyWith(
                        color: Paper.ink,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _characteristics(p),
                      style: AquarelaTypography.bodyMedium.copyWith(
                        color: Paper.charcoal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _characteristics(Pigment p) {
    final parts = <String>[];
    parts.add('Absorção ${(p.absorption * 100).round()}%');
    if (p.granulation > 0) {
      parts.add('Granulação ${(p.granulation * 100).round()}%');
    }
    return parts.join(' · ');
  }
}

class _PigmentGrid extends StatelessWidget {
  const _PigmentGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      buildWhen: (a, b) => a.currentPigment != b.currentPigment,
      builder: (context, state) {
        final config = PremiumConfig.current;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < Pigment.curated.length; i++)
              _PigmentSwatch(
                pigment: Pigment.curated[i],
                isSelected: state.currentPigment == Pigment.curated[i].id,
                isLocked: !config.isPremium && i >= config.maxPigments,
                onTap: () => _onPigmentTapped(context, i),
              ),
          ],
        );
      },
    );
  }

  void _onPigmentTapped(BuildContext context, int index) {
    final config = PremiumConfig.current;
    final isLocked = !config.isPremium && index >= config.maxPigments;
    if (isLocked) {
      _openPaywallForLockedPigment(context);
      return;
    }
    context.read<CanvasCubit>().setPigment(Pigment.curated[index].id);
  }

  void _openPaywallForLockedPigment(BuildContext context) {
    // Open the paywall screen above the palette sheet.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(
          onClose: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class _PigmentSwatch extends StatelessWidget {
  const _PigmentSwatch({
    required this.pigment,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  final Pigment pigment;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? pigment.color.withValues(alpha: 0.3)
                        : pigment.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? BrandPigment.ultramar
                          : Paper.ink.withValues(alpha: 0.2),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Paper.shadow(opacity: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: LockBadge(size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              pigment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AquarelaTypography.caption.copyWith(
                color: Paper.charcoal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrushControls extends StatelessWidget {
  const _BrushControls();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      builder: (context, state) {
        return Column(
          children: [
            _SliderRow(
              icon: Icons.brush_outlined,
              label: 'Tamanho',
              value: state.currentBrush.size,
              min: 1,
              max: 50,
              onChanged: (v) => context.read<CanvasCubit>().setBrushSize(v),
            ),
            _SliderRow(
              icon: Icons.water_drop_outlined,
              label: 'Água',
              value: state.currentBrush.waterRatio,
              min: 0,
              max: 1,
              onChanged: (v) => context.read<CanvasCubit>().setWaterRatio(v),
            ),
            _SliderRow(
              icon: Icons.opacity_rounded,
              label: 'Opacidade',
              value: state.currentBrush.opacity,
              min: 0.5,
              max: 1,
              onChanged: (v) => context.read<CanvasCubit>().setOpacity(v),
            ),
          ],
        );
      },
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Paper.charcoal),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AquarelaTypography.caption.copyWith(color: Paper.charcoal),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: BrandPigment.ultramar,
            inactiveColor: Paper.mist,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toStringAsFixed(max == 1 ? 2 : 0),
            textAlign: TextAlign.right,
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
