import '../onboarding_slide.dart';

abstract interface class OnboardingRepository {
  List<OnboardingSlide> getSlides();

  Future<bool> isSeen();

  Future<void> markSeen();
}
