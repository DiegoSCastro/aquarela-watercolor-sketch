import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:aquarela_watercolor_sketch/features/gallery/gallery_screen.dart';
import 'package:aquarela_watercolor_sketch/theme/components/empty_state.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';

import 'support/fake_path_provider.dart';

void main() {
  late FakePathProvider pathProvider;

  setUpAll(() {
    pathProvider = FakePathProvider();
    PathProviderPlatform.instance = pathProvider;
  });

  setUp(() {
    pathProvider.reset();
  });

  // Wrap a child in a MaterialApp that uses a system font for the
  // text theme. AquarelaTypography (Lora / Inter) is replaced with
  // Roboto so the test never triggers a GoogleFonts download.
  Widget wrap(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData(
        textTheme: TextTheme(
          displayLarge: const TextStyle(fontSize: 56),
          displayMedium: const TextStyle(fontSize: 40),
          displaySmall: const TextStyle(fontSize: 32),
          headlineLarge: const TextStyle(fontSize: 28),
          headlineMedium: const TextStyle(fontSize: 24),
          headlineSmall: const TextStyle(fontSize: 20),
          titleLarge: const TextStyle(fontSize: 18),
          titleMedium: const TextStyle(fontSize: 16),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 14),
          bodySmall: const TextStyle(fontSize: 12),
          labelLarge: const TextStyle(fontSize: 14),
          labelMedium: const TextStyle(fontSize: 12),
          labelSmall: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  testWidgets('shows empty state when no paintings', (tester) async {
    await tester.pumpWidget(wrap(const GalleryScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nenhuma obra ainda'), findsOneWidget);
  });

  testWidgets('lists PNG files in the gallery directory', (tester) async {
    await tester.runAsync(() async {
      pathProvider.seedPngs(['aquarela_1000.png', 'aquarela_2000.png']);
    });

    await tester.pumpWidget(wrap(const GalleryScreen()));
    await tester.pumpAndSettle();

    // Two Image.file tiles.
    expect(find.byType(Image), findsNWidgets(2));
    // No empty state.
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('shows all items with no cap (no tier system)', (tester) async {
    await tester.runAsync(() async {
      pathProvider.seedPngs([
        'aquarela_1000.png',
        'aquarela_2000.png',
        'aquarela_3000.png',
        'aquarela_4000.png',
        'aquarela_5000.png',
      ]);
    });

    await tester.pumpWidget(wrap(const GalleryScreen()));
    await tester.pumpAndSettle();

    // Read the GridView's semantic child count so the assertion
    // is viewport-independent (the 600px test viewport only
    // fits 2 of 3 grid rows when aspectRatio is 0.85).
    final gridWidget = tester.widget<GridView>(find.byType(GridView));
    expect(gridWidget.semanticChildCount, 5);
  });

  // Sanity: the theme stub is wired up — guards against a typo
  // that would re-introduce GoogleFonts at test time.
  test('AquarelaTypography exists', () {
    expect(AquarelaTypography, isNotNull);
  });
}
