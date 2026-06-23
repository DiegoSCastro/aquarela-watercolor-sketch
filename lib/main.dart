import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquarela_watercolor_sketch/features/onboarding/onboarding_screen.dart';
import 'package:aquarela_watercolor_sketch/theme/aquarela_theme.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Paper.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AquarelaApp());
}

class AquarelaApp extends StatelessWidget {
  const AquarelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquarela',
      debugShowCheckedModeBanner: false,
      theme: AquarelaTheme.light(),
      home: const OnboardingScreen(),
    );
  }
}
