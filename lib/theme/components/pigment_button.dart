import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/motion.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/shadow.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Primary CTA button. Paper-feel: settles into the surface.
class PigmentButton extends StatefulWidget {
  const PigmentButton({
    required this.label,
    required this.onPressed,
    this.variant = PigmentButtonVariant.primary,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final PigmentButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  State<PigmentButton> createState() => _PigmentButtonState();
}

enum PigmentButtonVariant { primary, secondary, ghost }

class _PigmentButtonState extends State<PigmentButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final (bg, fg) = switch (widget.variant) {
      PigmentButtonVariant.primary => (BrandPigment.ultramar, Paper.white),
      PigmentButtonVariant.secondary => (Paper.cream, Paper.ink),
      PigmentButtonVariant.ghost => (Colors.transparent, BrandPigment.ultramar),
    };

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: AquarelaTypography.button.copyWith(color: fg),
        ),
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: Motion.quick,
      curve: Motion.wet,
      child: AnimatedContainer(
        duration: Motion.quick,
        curve: Motion.wet,
        decoration: BoxDecoration(
          color: isDisabled ? bg.withValues(alpha: 0.4) : bg,
          borderRadius: BorderRadius.circular(RadiusToken.md),
          boxShadow: widget.variant == PigmentButtonVariant.primary
              ? (_pressed
                    ? AquarelaShadow.paper2List
                    : AquarelaShadow.paper1List)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(RadiusToken.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
