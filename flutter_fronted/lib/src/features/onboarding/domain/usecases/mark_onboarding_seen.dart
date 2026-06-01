import '../repositories/onboarding_repository.dart';

class MarkOnboardingSeenUseCase {
  const MarkOnboardingSeenUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> call() => _repository.markSeen();
}
