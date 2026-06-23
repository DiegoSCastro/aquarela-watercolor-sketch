import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/radius.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

/// Root theme for Aquarela. Built on paper-first principles:
/// cold press background, painterly pigment accents, organic radii.
class AquarelaTheme {
  const AquarelaTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: BrandPigment.ultramar,
      onPrimary: Paper.white,
      secondary: BrandPigment.burntSienna,
      onSecondary: Paper.white,
      tertiary: BrandPigment.cadmiumYellow,
      onTertiary: Paper.ink,
      error: const Color(0xFFC0392B),
      onError: Paper.white,
      surface: Paper.white,
      onSurface: Paper.ink,
      surfaceContainerHighest: Paper.cream,
      onSurfaceVariant: Paper.charcoal,
      outline: Paper.mist,
      outlineVariant: const Color(0x4DA8A199), // mist @ 30%
      shadow: Paper.shadow(opacity: 0.1),
      scrim: const Color(0x661A1814),
      inverseSurface: Paper.ink,
      onInverseSurface: Paper.white,
      inversePrimary: const Color(0xFF6F8FE0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Paper.white,
      canvasColor: Paper.white,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: AquarelaTypography.displayLarge,
        displayMedium: AquarelaTypography.displayMedium,
        displaySmall: AquarelaTypography.displaySmall,
        headlineLarge: AquarelaTypography.headlineLarge,
        headlineMedium: AquarelaTypography.headlineLarge,
        headlineSmall: AquarelaTypography.headlineSmall,
        titleLarge: AquarelaTypography.headlineSmall,
        titleMedium: AquarelaTypography.subhead,
        titleSmall: AquarelaTypography.subhead,
        bodyLarge: AquarelaTypography.bodyLarge,
        bodyMedium: AquarelaTypography.bodyMedium,
        bodySmall: AquarelaTypography.caption,
        labelLarge: AquarelaTypography.button.copyWith(color: Paper.ink),
        labelMedium: AquarelaTypography.caption,
        labelSmall: AquarelaTypography.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Paper.white,
        foregroundColor: Paper.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AquarelaTypography.headlineSmall,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandPigment.ultramar,
          foregroundColor: Paper.white,
          textStyle: AquarelaTypography.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusToken.md),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandPigment.ultramar,
          textStyle: AquarelaTypography.subhead,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Paper.white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Paper.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: BrandPigment.ultramar,
        inactiveTrackColor: Paper.mist.withValues(alpha: 0.4),
        thumbColor: Paper.white,
        overlayColor: BrandPigment.ultramar.withValues(alpha: 0.1),
        trackHeight: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x33A8A199), // mist @ 20%
        thickness: 0.5,
        space: 0,
      ),
      iconTheme: const IconThemeData(color: Paper.ink, size: 24),
    );
  }
}
