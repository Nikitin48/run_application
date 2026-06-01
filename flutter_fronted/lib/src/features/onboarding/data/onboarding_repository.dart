import '../domain/onboarding_slide.dart';
import '../domain/repositories/onboarding_repository.dart';
import 'onboarding_local_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  List<OnboardingSlide> getSlides() {
    return const [
      OnboardingSlide(
        eyebrow: 'ТВОЯ КАРТА',
        title: 'Беги и захватывай карту',
        body:
            'Пробеги замкнутый маршрут, и приложение превратит его в твою территорию.',
        visual: OnboardingVisual.route,
      ),
      OnboardingSlide(
        eyebrow: 'ЗАЩИТА',
        title: 'Защищай свои владения',
        body:
            'После захвата территория получает защиту. Слишком маленькие зоны и случайные касания не учитываются.',
        visual: OnboardingVisual.shield,
      ),
      OnboardingSlide(
        eyebrow: 'СОРЕВНОВАНИЕ',
        title: 'Стань хозяином района',
        body:
            'Пересекай чужие территории, возвращай спорные зоны и расширяй влияние с каждой пробежкой.',
        visual: OnboardingVisual.contest,
      ),
    ];
  }

  @override
  Future<bool> isSeen() => _localDataSource.isSeen();

  @override
  Future<void> markSeen() => _localDataSource.markSeen();
}
