import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';

/// Three pulsing dots in ultramar — for "thinking" / "loading" states.
class PigmentLoader extends StatefulWidget {
  const PigmentLoader({this.size = 8, this.color = BrandPigment.ultramar, super.key});

  final double size;
  final Color color;

  @override
  State<PigmentLoader> createState() => _PigmentLoaderState();
}

class _PigmentLoaderState extends State<PigmentLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_controller.value + i / 3) % 1.0);
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
