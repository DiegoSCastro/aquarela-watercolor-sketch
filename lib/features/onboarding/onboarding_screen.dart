import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aquarela_watercolor_sketch/main.dart' show navigateAfterOnboarding;
import 'package:aquarela_watercolor_sketch/theme/components/pigment_button.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/motion.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/spacing.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/typography.dart';
import 'illustrations/slide1_pocket.dart';
import 'illustrations/slide2_bleed.dart';
import 'illustrations/slide3_gallery.dart';
import 'onboarding_cubit.dart';

/// 3-slide onboarding flow. Paper-first, hand-crafted illustrations.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      illustration: Slide1PocketIllustration(),
      title: 'Aquarela no seu bolso',
      subtitle: 'Pinte com pigmentos que sangram, escorrem e secam — como na vida real.',
    ),
    _OnboardingSlide(
      illustration: Slide2BleedIllustration(),
      title: 'Pigmento que respira',
      subtitle: 'Cada cor carrega sua própria personalidade. Molhe o pincel, solte o controle.',
    ),
    _OnboardingSlide(
      illustration: Slide3GalleryIllustration(),
      title: 'Suas obras, guardadas',
      subtitle: 'Salve em alta resolução e compartilhe com o mundo. Suas pinturas ficam no seu celular.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paper.white,
      body: SafeArea(
        child: BlocBuilder<OnboardingCubit, int>(
          builder: (context, page) {
            return Column(
              children: [
                // Top bar: skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (page < OnboardingCubit.totalPages - 1)
                        TextButton(
                          onPressed: () => context
                              .read<OnboardingCubit>()
                              .goTo(OnboardingCubit.totalPages - 1),
                          child: Text(
                            'Pular',
                            style: AquarelaTypography.caption.copyWith(
                              color: Paper.mist,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Animated page content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.standard,
                    switchInCurve: Motion.wet,
                    switchOutCurve: Motion.dry,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _OnboardingPageView(
                      key: ValueKey(page),
                      slide: _slides[page],
                    ),
                  ),
                ),

                // Page indicator + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.xl,
                    Space.lg,
                    Space.xl,
                    Space.xl,
                  ),
                  child: Column(
                    children: [
                      _PageIndicator(current: page, total: OnboardingCubit.totalPages),
                      const SizedBox(height: Space.xl),
                      PigmentButton(
                        label: page == OnboardingCubit.totalPages - 1
                            ? 'Começar a pintar'
                            : 'Próximo',
                        icon: page == OnboardingCubit.totalPages - 1
                            ? Icons.brush_outlined
                            : Icons.arrow_forward_rounded,
                        expand: true,
                        onPressed: () {
                          if (page < OnboardingCubit.totalPages - 1) {
                            context.read<OnboardingCubit>().next();
                          } else {
                            navigateAfterOnboarding(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.slide, super.key});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration — directly on paper, no frame
          SizedBox(
            width: 320,
            height: 320,
            child: Center(child: slide.illustration),
          ),
          const SizedBox(height: Space.xxl),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AquarelaTypography.displaySmall.copyWith(
              color: Paper.ink,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: Space.md),

          // Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: AquarelaTypography.bodyLarge.copyWith(
              color: Paper.charcoal,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: Motion.standard,
          curve: Motion.wet,
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? BrandPigment.ultramar : Paper.mist.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
}
