import '../repositories/onboarding_repository.dart';

class GetOnboardingSeenUseCase {
  const GetOnboardingSeenUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<bool> call() => _repository.isSeen();
}
