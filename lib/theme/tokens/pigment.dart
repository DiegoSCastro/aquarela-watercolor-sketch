import 'package:flutter/material.dart';

/// Core brand pigments — 4 colors that define Aquarela's identity.
/// These are real watercolor pigment names with their canonical hex values.
///
/// Different from the curated 12-pigment user palette in
/// `lib/engine/pigment.dart` — these are the brand identity colors
/// used in the UI (CTAs, indicators, etc.).
class BrandPigment {
  const BrandPigment._();

  /// #1E3A8A — Ultramarine (lapis lazuli). Primary accent, CTAs.
  static const Color ultramar = Color(0xFF1E3A8A);

  /// #9B5D3A — Burnt Sienna. Secondary accent, highlights.
  static const Color burntSienna = Color(0xFF9B5D3A);

  /// #F2C94C — Cadmium Yellow. Alerts, success states.
  static const Color cadmiumYellow = Color(0xFFF2C94C);

  /// #2D3142 — Payne's Gray. Primary text, icons.
  static const Color paynesGray = Color(0xFF2D3142);
}
