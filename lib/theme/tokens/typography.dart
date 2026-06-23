import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';

/// Typography — Lora (display serif) + Inter (UI sans).
/// Lora evokes the artist's notebook; Inter handles functional UI.
class AquarelaTypography {
  const AquarelaTypography._();

  /// Display 56 / Lora 500 — splash, hero titles.
  static TextStyle displayLarge = GoogleFonts.lora(
    fontSize: 56.0,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -1.5,
    color: Paper.ink,
  );

  /// Display 40 / Lora 500 — onboarding titles.
  static TextStyle displayMedium = GoogleFonts.lora(
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 1.15,
    letterSpacing: -1.0,
    color: Paper.ink,
  );

  /// Display 32 / Lora 500 — section heads.
  static TextStyle displaySmall = GoogleFonts.lora(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.5,
    color: Paper.ink,
  );

  /// Headline 24 / Inter 600 — feature highlights.
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: Paper.ink,
  );

  /// Headline 20 / Inter 600 — card titles.
  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Paper.ink,
  );

  /// Subhead 18 / Inter 500 — emphasized body.
  static TextStyle subhead = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Paper.charcoal,
  );

  /// Body 16 / Inter 400 — default body text.
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Paper.charcoal,
  );

  /// Body 14 / Inter 400 — secondary body.
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Paper.charcoal,
  );

  /// Button 16 / Inter 600 — CTA labels.
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: Paper.white,
  );

  /// Caption 12 / Inter 500 — labels, metadata.
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.4,
    color: Paper.charcoal,
  );

  /// Accent color override for selected/highlighted text.
  static TextStyle accent(TextStyle base) =>
      base.copyWith(color: BrandPigment.ultramar);
}
