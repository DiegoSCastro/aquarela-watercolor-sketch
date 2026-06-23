import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Centered "nothing here yet" placeholder. Used by the gallery
/// and any future empty list. Icon + title + optional helper.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Paper.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Paper.charcoal),
          ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            style: AquarelaTypography.headlineSmall.copyWith(
              color: Paper.ink,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              message!,
              style: AquarelaTypography.bodyMedium.copyWith(
                color: Paper.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
