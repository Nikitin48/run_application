class OnboardingSlide {
  const OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.visual,
  });

  final String eyebrow;
  final String title;
  final String body;
  final OnboardingVisual visual;
}

enum OnboardingVisual { route, shield, contest }
