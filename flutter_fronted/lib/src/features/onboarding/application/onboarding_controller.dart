import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_local_data_source.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_slide.dart';
import '../domain/repositories/onboarding_repository.dart';
import '../domain/usecases/get_onboarding_seen.dart';
import '../domain/usecases/get_onboarding_slides.dart';
import '../domain/usecases/mark_onboarding_seen.dart';

enum OnboardingStatus { unknown, unseen, seen }

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return const OnboardingLocalDataSource();
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

final getOnboardingSeenUseCaseProvider = Provider<GetOnboardingSeenUseCase>((
  ref,
) {
  return GetOnboardingSeenUseCase(ref.watch(onboardingRepositoryProvider));
});

final markOnboardingSeenUseCaseProvider = Provider<MarkOnboardingSeenUseCase>((
  ref,
) {
  return MarkOnboardingSeenUseCase(ref.watch(onboardingRepositoryProvider));
});

final getOnboardingSlidesUseCaseProvider = Provider<GetOnboardingSlidesUseCase>(
  (ref) {
    return GetOnboardingSlidesUseCase(ref.watch(onboardingRepositoryProvider));
  },
);

final onboardingSlidesProvider = Provider<List<OnboardingSlide>>((ref) {
  return ref.watch(getOnboardingSlidesUseCaseProvider)();
});

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingStatus>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingStatus> {
  @override
  OnboardingStatus build() {
    _load();
    return OnboardingStatus.unknown;
  }

  Future<void> _load() async {
    final seen = await ref.read(getOnboardingSeenUseCaseProvider)();
    state = seen ? OnboardingStatus.seen : OnboardingStatus.unseen;
  }

  Future<void> markSeen() async {
    await ref.read(markOnboardingSeenUseCaseProvider)();
    state = OnboardingStatus.seen;
  }
}
