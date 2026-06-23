import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/components/lock_badge.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart' show BrandPigment;
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
            Text(
              'Pigmentos',
              style: AquarelaTypography.headlineLarge.copyWith(
                color: Paper.ink,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: Space.md),
            const _PigmentGrid(),
            const SizedBox(height: Space.lg),
            const _BrushControls(),
          ],
        ),
      ),
    );
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
                onTap: () {
                  if (!config.isPremium && i >= config.maxPigments) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Pigmento Pro — upgrade no paywall'),
                        backgroundColor: BrandPigment.cadmiumYellow,
                      ),
                    );
                    return;
                  }
                  context.read<CanvasCubit>().setPigment(Pigment.curated[i].id);
                },
              ),
          ],
        );
      },
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
              onChanged: (v) =>
                  context.read<CanvasCubit>().setWaterRatio(v),
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
