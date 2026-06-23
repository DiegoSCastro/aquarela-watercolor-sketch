import 'package:flutter/animation.dart';

/// Motion tokens — durations and curves that feel like wet paint settling.
class Motion {
  const Motion._();

  /// 150ms — hover, press feedback.
  static const Duration quick = Duration(milliseconds: 150);

  /// 300ms — standard transitions (screens, modals).
  static const Duration standard = Duration(milliseconds: 300);

  /// 500ms — splash, onboarding enter, deliberate moments.
  static const Duration deliberate = Duration(milliseconds: 500);

  /// Default curve — paint settling. Use for almost everything.
  static const Curve wet = Curves.easeOutCubic;

  /// Reversible state changes (toggle, open/close).
  static const Curve dry = Curves.easeInOutCubic;
}
