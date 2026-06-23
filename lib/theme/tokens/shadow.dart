import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';

/// Paper depth shadows — soft, organic, never harsh.
class AquarelaShadow {
  const AquarelaShadow._();

  /// Subtle elevation for resting cards.
  static const BoxShadow paper1 = BoxShadow(
    color: Color(0x1A1A1814), // Paper.shadow @ 0.10
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  /// Raised elevation for hovered/pressed elements.
  static const BoxShadow paper2 = BoxShadow(
    color: Color(0x141A1814), // Paper.shadow @ 0.08
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  /// List of paper1 shadow for use in BoxDecoration(boxShadow:).
  static const List<BoxShadow> paper1List = [paper1];

  /// List of paper2 shadow for use in BoxDecoration(boxShadow:).
  static const List<BoxShadow> paper2List = [paper2];

  /// Helper to build a BoxDecoration with paper1 elevation.
  static BoxDecoration paperSurface({
    Color color = Paper.white,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: paper1List,
    );
  }
}
