import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_cubit.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Bottom sheet that lets the user pick a pigment, choose a brush
/// tip, and adjust brush settings. Lives inside the canvas sheet —
/// receives the [CanvasCubit] via BlocProvider.value from the parent.
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
            const _SelectedPigmentCard(),
            const SizedBox(height: Space.lg),
            const _BrushPicker(),
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

/// 6-tip brush picker. The icons are deliberately stylised to
/// suggest the tip shape (round dot, flat bar, fan spread, mop
/// blob) rather than literal brushes.
class _BrushPicker extends StatelessWidget {
  const _BrushPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pincéis',
          style: AquarelaTypography.headlineSmall.copyWith(
            color: Paper.ink,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: Space.sm),
        BlocBuilder<CanvasCubit, CanvasState>(
          buildWhen: (a, b) => a.currentBrush.id != b.currentBrush.id,
          builder: (context, state) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final id in BrushId.values)
                  _BrushIcon(
                    brush: brushFor(id),
                    isSelected: state.currentBrush.id == brushFor(id).id,
                    onTap: () =>
                        context.read<CanvasCubit>().setBrush(brushFor(id)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BrushIcon extends StatelessWidget {
  const _BrushIcon({
    required this.brush,
    required this.isSelected,
    required this.onTap,
  });

  final Brush brush;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Paper.cream : Paper.white,
              borderRadius: BorderRadius.circular(RadiusToken.md),
              border: Border.all(
                color: isSelected
                    ? BrandPigment.ultramar
                    : Paper.mist.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(28, 28),
              painter: _BrushTipPainter(brush: brush),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 48,
            child: Text(
              _label(brush.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AquarelaTypography.caption.copyWith(
                color: isSelected ? Paper.ink : Paper.charcoal,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String id) {
    switch (id) {
      case 'round_small':
        return 'Redondo P';
      case 'round_medium':
        return 'Redondo M';
      case 'round_large':
        return 'Redondo G';
      case 'flat':
        return 'Chato';
      case 'fan':
        return 'Leque';
      case 'mop':
        return 'Mop';
      default:
        return id;
    }
  }
}

/// Stylised painter for each brush tip. Keeps the icons readable
/// at 28x28 and consistent with the actual stamp geometry.
class _BrushTipPainter extends CustomPainter {
  const _BrushTipPainter({required this.brush});

  final Brush brush;

  @override
  void paint(Canvas canvas, Size size) {
    final color = Paper.charcoal;
    final paint = Paint()..color = color;
    final c = size.center(Offset.zero);
    switch (brush.type) {
      case BrushType.round:
        canvas.drawCircle(c, brush.size / 4, paint);
      case BrushType.flat:
        final rect = Rect.fromCenter(
          center: c,
          width: 22,
          height: 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          paint,
        );
      case BrushType.fan:
        for (var i = -2; i <= 2; i++) {
          final dx = i * 4.0;
          canvas.drawLine(
            Offset(c.dx + dx, c.dy - 8),
            Offset(c.dx + dx, c.dy + 8),
            paint..strokeWidth = 1.2,
          );
        }
      case BrushType.mop:
        final path = Path()
          ..addOval(
            Rect.fromCenter(center: c, width: 22, height: 18),
          );
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BrushTipPainter old) => old.brush.id != brush.id;
}

class _PigmentGrid extends StatelessWidget {
  const _PigmentGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      buildWhen: (a, b) => a.currentPigment != b.currentPigment,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pigmentos',
              style: AquarelaTypography.headlineSmall.copyWith(
                color: Paper.ink,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in Pigment.curated)
                  _PigmentSwatch(
                    pigment: p,
                    isSelected: state.currentPigment == p.id,
                    onTap: () => context.read<CanvasCubit>().setPigment(p.id),
                  ),
              ],
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
    required this.onTap,
  });

  final Pigment pigment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pigment.color,
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
              max: 80,
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
              min: 0.3,
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
