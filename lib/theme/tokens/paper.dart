import 'package:flutter/material.dart';

/// Paper neutrals — the substrate on which everything else is painted.
/// Inspired by cold-press and hot-press watercolor paper.
class Paper {
  const Paper._();

  /// #FAF8F4 — Cold press paper. Default app background.
  static const Color white = Color(0xFFFAF8F4);

  /// #F2EDE3 — Hot press paper. Secondary surface, slightly warmer.
  static const Color cream = Color(0xFFF2EDE3);

  /// #1A1814 — Ink. Primary text on light surfaces.
  static const Color ink = Color(0xFF1A1814);

  /// #3D3A35 — Charcoal. Secondary text, subtle labels.
  static const Color charcoal = Color(0xFF3D3A35);

  /// #A8A199 — Mist. Disabled text, dividers, subtle UI marks.
  static const Color mist = Color(0xFFA8A199);

  /// Soft drop shadow on paper — never pure black.
  static Color shadow({double opacity = 0.06}) =>
      const Color(0xFF1A1814).withValues(alpha: opacity);
}
