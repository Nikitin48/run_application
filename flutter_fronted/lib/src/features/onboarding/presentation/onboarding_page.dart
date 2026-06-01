import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref.read(onboardingControllerProvider.notifier).markSeen();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _next(int slideCount) async {
    if (_currentPage == slideCount - 1) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(onboardingSlidesProvider);
    final currentSlide = slides[_currentPage];
    final currentStyle = onboardingSlideStyle(currentSlide);
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: OnboardingBackground(accent: currentStyle.accent),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      OnboardingBrandMark(color: currentStyle.accent),
                      const Spacer(),
                      TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: const Text('Пропустить'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (value) {
                        setState(() => _currentPage = value);
                      },
                      itemCount: slides.length,
                      itemBuilder: (context, index) {
                        return OnboardingSlideView(
                          slide: slides[index],
                          compact: compact,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OnboardingPageDots(
                        count: slides.length,
                        currentIndex: _currentPage,
                        color: currentStyle.accent,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 168,
                        child: FilledButton(
                          onPressed: _finishing
                              ? null
                              : () => _next(slides.length),
                          style: FilledButton.styleFrom(
                            backgroundColor: currentStyle.accent,
                            foregroundColor: currentStyle.ctaForeground,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              _currentPage == slides.length - 1
                                  ? 'Начать'
                                  : 'Далее',
                              key: ValueKey(_currentPage),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
