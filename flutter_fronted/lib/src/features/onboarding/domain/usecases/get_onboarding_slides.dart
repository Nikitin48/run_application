import '../onboarding_slide.dart';
import '../repositories/onboarding_repository.dart';

class GetOnboardingSlidesUseCase {
  const GetOnboardingSlidesUseCase(this._repository);

  final OnboardingRepository _repository;

  List<OnboardingSlide> call() => _repository.getSlides();
}
