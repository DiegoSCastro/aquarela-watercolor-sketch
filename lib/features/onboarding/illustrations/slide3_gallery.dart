import 'package:flutter/material.dart';

/// Slide 3: Suas obras, guardadas.
/// AI-generated watercolor illustration (gallery grid + share icon).
class Slide3GalleryIllustration extends StatelessWidget {
  const Slide3GalleryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/onboarding/slide3_gallery.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
