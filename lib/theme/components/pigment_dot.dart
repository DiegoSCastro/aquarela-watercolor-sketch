import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/shadow.dart';

/// A circular pigment swatch with optional lock/selected state.
class PigmentDot extends StatelessWidget {
  const PigmentDot({
    required this.color,
    this.size = 48,
    this.locked = false,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final Color color;
  final double size;
  final bool locked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? BrandPigment.ultramar : Paper.white,
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Paper.shadow(opacity: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
            ...AquarelaShadow.paper1List,
          ],
        ),
        child: locked
            ? Icon(
                Icons.lock_rounded,
                size: size * 0.45,
                color: Paper.charcoal.withValues(alpha: 0.8),
              )
            : null,
      ),
    );
  }
}
