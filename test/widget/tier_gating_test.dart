import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/features/home/home_placeholder.dart';
import 'package:aquarela_watercolor_sketch/features/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a screen inside a minimal MaterialApp so it has a Navigator
/// and a Directionality — both required by widgets that use
/// Navigator.of(context) or default text direction.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: child),
  );
}

void main() {
  group('HomePlaceholder (free tier)', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: false));
    tearDown(PremiumConfig.resetForTest);

    testWidgets('shows upgrade banner', (tester) async {
      await _pump(tester, const HomePlaceholder());
      await tester.pumpAndSettle();
      expect(find.text('Plano Free'), findsOneWidget);
      expect(find.text('Conhecer Pro'), findsOneWidget);
    });

    testWidgets('shows 4-of-12 pigments and 1-of-6 brushes', (tester) async {
      await _pump(tester, const HomePlaceholder());
      await tester.pumpAndSettle();
      expect(find.text('4 de 12'), findsOneWidget);
      expect(find.text('1 de 6'), findsOneWidget);
    });
  });

  group('HomePlaceholder (pro tier)', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: true));
    tearDown(PremiumConfig.resetForTest);

    testWidgets('hides upgrade banner and shows "todos"', (tester) async {
      await _pump(tester, const HomePlaceholder());
      await tester.pumpAndSettle();
      expect(find.text('Plano Pro'), findsOneWidget);
      expect(find.text('Conhecer Pro'), findsNothing);
      expect(find.text('12 (todos)'), findsOneWidget);
      expect(find.text('6 (todos)'), findsOneWidget);
    });
  });

  group('PaywallScreen', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: false));
    tearDown(PremiumConfig.resetForTest);

    testWidgets('shows both tier cards and continue-free CTA', (tester) async {
      await _pump(tester, const PaywallScreen());
      await tester.pumpAndSettle();
      expect(find.text('Aquarela Pro'), findsOneWidget);
      expect(find.text('Pro'), findsWidgets);
      expect(find.text('Palette Pack'), findsOneWidget);
      expect(find.text('Continuar no Free'), findsOneWidget);
      expect(find.text('Restaurar compras'), findsOneWidget);
    });

    testWidgets('hides close button when onClose is null', (tester) async {
      await _pump(tester, const PaywallScreen());
      await tester.pumpAndSettle();
      // No close icon in the top bar
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('shows close button when onClose is provided', (tester) async {
      await _pump(
        tester,
        PaywallScreen(onClose: () {}),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
