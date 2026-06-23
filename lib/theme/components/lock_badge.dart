import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/motion.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';

/// Small lock badge that sits on top of a Pro-only feature
/// (locked pigment dot, locked brush icon, etc.).
///
/// Always shown in Pro gold (cadmium) so free users instantly know
/// "I can unlock this" without breaking the paper palette.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Pigment.cadmiumYellow,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Paper.shadow(opacity: 0.18),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.lock_rounded,
        size: size * 0.62,
        color: Paper.ink,
      ),
    );
  }
}

/// Inline upgrade banner. Used at the top of the canvas, the gallery,
/// and the paywall screen itself. Tap → [onUpgrade] (usually navigates
/// to the paywall).
///
/// Animates in with a wet curve so it feels like a brushstroke, not
/// a system notification.
class UpgradeBanner extends StatefulWidget {
  const UpgradeBanner({
    required this.onUpgrade,
    this.message = 'Desbloqueie todos os pigmentos e pincéis',
    this.ctaLabel = 'Conhecer Pro',
    super.key,
  });

  final VoidCallback onUpgrade;
  final String message;
  final String ctaLabel;

  @override
  State<UpgradeBanner> createState() => _UpgradeBannerState();
}

class _UpgradeBannerState extends State<UpgradeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Motion.wet);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Motion.wet));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onUpgrade,
            borderRadius: BorderRadius.circular(RadiusToken.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Pigment.cadmiumYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusToken.md),
                border: Border.all(
                  color: Pigment.cadmiumYellow.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Pigment.ultramar,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Paper.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Pigment.ultramar,
                      borderRadius: BorderRadius.circular(RadiusToken.full),
                    ),
                    child: Text(
                      widget.ctaLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Paper.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
