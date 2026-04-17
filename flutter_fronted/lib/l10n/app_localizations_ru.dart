// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Беговой трекер';

  @override
  String get loginTitle => 'Вход';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get emailLabel => 'Почта';

  @override
  String get displayNameLabel => 'Имя';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get loginAction => 'Войти';

  @override
  String get registerAction => 'Создать аккаунт';

  @override
  String get switchToLogin => 'Уже есть аккаунт? Войти';

  @override
  String get switchToRegister => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get loading => 'Загрузка…';

  @override
  String get appBootstrapping => 'Подготовка приложения…';

  @override
  String get authValidationEmailInvalid => 'Введите корректный email.';

  @override
  String get authValidationPasswordMinLength =>
      'Пароль должен быть не короче 8 символов.';

  @override
  String get authInvalidCredentials => 'Неверные учетные данные';

  @override
  String get authLegalNotice => 'Продолжая, вы соглашаетесь с';

  @override
  String get authPrivacyPolicyAction => 'Политикой конфиденциальности.';

  @override
  String get authTermsOfUseAction => 'Правилами пользования';

  @override
  String get mapTitle => 'Карта';

  @override
  String get historiesTitle => 'Истории';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get logout => 'Выйти';

  @override
  String get followOn => 'Слежение';

  @override
  String get followOff => 'Ко мне';

  @override
  String get testModeOn => 'Тестовый режим';

  @override
  String get testModeOff => 'Тестовый режим';

  @override
  String territoriesCount(Object count) {
    return 'Территорий: $count';
  }

  @override
  String get territoriesLoadError => 'Ошибка загрузки территорий';

  @override
  String get territoryStolenTitle => 'Территория отжата';

  @override
  String territoryStolenMessage(Object area) {
    return 'У вас отжали $area';
  }

  @override
  String get refresh => 'Обновить';

  @override
  String get close => 'Закрыть';

  @override
  String get runReady => 'Готово';

  @override
  String get runRunning => 'Бег';

  @override
  String get runPaused => 'Пауза';

  @override
  String get runFinishing => 'Завершение…';

  @override
  String get runStart => 'Старт';

  @override
  String get runPause => 'Пауза';

  @override
  String get runResume => 'Продолжить';

  @override
  String get runFinish => 'Финиш';

  @override
  String pointsCount(Object count) {
    return 'Точек: $count';
  }

  @override
  String get runSummaryTitle => 'Итоги пробежки';

  @override
  String get runSummaryNoData => 'Нет данных о завершённой пробежке.';

  @override
  String get backToMap => 'Вернуться к карте';

  @override
  String get done => 'Готово';

  @override
  String get distance => 'Дистанция';

  @override
  String get elapsed => 'Общее время';

  @override
  String get paused => 'Пауза';

  @override
  String get moving => 'В движении';

  @override
  String get avgPaceMoving => 'Средний темп';

  @override
  String get avgSpeedOverall => 'Средняя скорость';

  @override
  String get capturedArea => 'Захваченная площадь';

  @override
  String get victims => 'Затронуто пользователей';

  @override
  String get noLocationYet => 'Местоположение ещё не получено';

  @override
  String get enableLocationFirst => 'Сначала включите геолокацию';

  @override
  String get runFinished => 'Пробежка завершена';

  @override
  String runLiveStats(Object area, Object distance, Object victims) {
    return 'Дистанция: $distance • Захват: $area • Отжато: $victims';
  }

  @override
  String runLiveDistanceOnly(Object distance) {
    return 'Дистанция: $distance';
  }

  @override
  String get runStartingSoon => 'Старт через…';

  @override
  String get profilePersonalSection => 'Персональные данные';

  @override
  String get profileAvatarUrlLabel => 'Ссылка на аватар';

  @override
  String get profileUploadAvatarAction => 'Выбрать фото';

  @override
  String get profileDeleteAvatarAction => 'Удалить аватар';

  @override
  String get profileAvatarUploadSuccess => 'Аватар обновлён';

  @override
  String get profileAvatarDeleteSuccess => 'Аватар удалён';

  @override
  String get profileEmailReadonlyHint => 'Email доступен только для чтения.';

  @override
  String get profileSaveProfileAction => 'Сохранить данные';

  @override
  String get profileTerritoryColorSection => 'Цвет территории';

  @override
  String get profileColorCurrent => 'Текущий цвет';

  @override
  String get profilePickCustomColor => 'Выбрать цвет';

  @override
  String get profileApplyColorAction => 'Применить';

  @override
  String get profileSaveColorAction => 'Сохранить цвет';

  @override
  String get profilePasswordSection => 'Смена пароля';

  @override
  String get profileCurrentPasswordLabel => 'Текущий пароль';

  @override
  String get profileNewPasswordLabel => 'Новый пароль';

  @override
  String get profileConfirmPasswordLabel => 'Подтвердите новый пароль';

  @override
  String get profileChangePasswordAction => 'Сменить пароль';

  @override
  String get profilePasswordChangedSuccess => 'Пароль успешно изменён';

  @override
  String get profilePasswordMismatchError =>
      'Новый пароль и подтверждение не совпадают.';

  @override
  String get profilePasswordMinLengthError =>
      'Новый пароль должен быть не короче 8 символов.';

  @override
  String get profileStatsSection => 'Статистика';

  @override
  String get profileRunsCount => 'Количество пробежек';

  @override
  String get profileOwnedArea => 'Общая площадь';

  @override
  String get profileSaveSuccess => 'Изменения сохранены';

  @override
  String get profileLevelLabel => 'Уровень профиля';

  @override
  String get profileXpLabel => 'Опыт профиля';

  @override
  String get profileSuccessfulCapturesLabel => 'Успешные захваты';

  @override
  String get profileTotalCapturedLabel => 'Суммарно захвачено';

  @override
  String get profileTotalVictimsLabel => 'Всего затронуто соперников';

  @override
  String get achievementsPopupTitle => 'Новые достижения';

  @override
  String get achievementsPopupIntroSingle =>
      'За этот забег вы открыли новую награду.';

  @override
  String get achievementsPopupIntroMultiple =>
      'За этот забег открыто сразу несколько наград.';

  @override
  String get achievementsPopupAction => 'Круто';

  @override
  String achievementsLevelUp(Object oldLevel, Object newLevel) {
    return 'Уровень повышен: $oldLevel -> $newLevel';
  }

  @override
  String get achievementsCollectionTitle => 'Коллекция достижений';

  @override
  String achievementsCollectionSummary(Object count, Object level, Object xp) {
    return 'Открыто $count | Уровень $level | $xp XP';
  }

  @override
  String get achievementsOpenAllAction => 'Все достижения';

  @override
  String get achievementsEmpty =>
      'Пока нет открытых достижений. Завершайте пробежки и захватывайте территорию.';

  @override
  String achievementsLoadError(Object error) {
    return 'Не удалось загрузить достижения: $error';
  }

  @override
  String get achievementsPageTitle => 'Все достижения';

  @override
  String get achievementsPageSubtitle =>
      'Ваши открытые награды и прогресс профиля';

  @override
  String get achievementTierBase => 'Базовое';

  @override
  String get achievementTierAdvanced => 'Продвинутое';

  @override
  String get achievementTierRare => 'Редкое';

  @override
  String get achievementTierLegendary => 'Легендарное';

  @override
  String get achievementRuns001Title => 'Первые шаги';

  @override
  String get achievementRuns001Description => 'Завершить 1 пробежку';

  @override
  String get achievementRuns005Title => 'Разогрев';

  @override
  String get achievementRuns005Description => 'Завершить 5 пробежек';

  @override
  String get achievementRuns010Title => 'В ритме';

  @override
  String get achievementRuns010Description => 'Завершить 10 пробежек';

  @override
  String get achievementRuns025Title => 'Не остановить';

  @override
  String get achievementRuns025Description => 'Завершить 25 пробежек';

  @override
  String get achievementRuns050Title => 'Машина бега';

  @override
  String get achievementRuns050Description => 'Завершить 50 пробежек';

  @override
  String get achievementSingleDistance1kTitle => 'Первый километр';

  @override
  String get achievementSingleDistance1kDescription =>
      'Пробежать 1 км за один забег';

  @override
  String get achievementSingleDistance5kTitle => 'Пятёрка';

  @override
  String get achievementSingleDistance5kDescription =>
      'Пробежать 5 км за один забег';

  @override
  String get achievementSingleDistance10kTitle => 'Десятка';

  @override
  String get achievementSingleDistance10kDescription =>
      'Пробежать 10 км за один забег';

  @override
  String get achievementSingleDistance21kTitle => 'Полумарафонец';

  @override
  String get achievementSingleDistance21kDescription =>
      'Пробежать 21.1 км за один забег';

  @override
  String get achievementSingleDistance42kTitle => 'Марафонец';

  @override
  String get achievementSingleDistance42kDescription =>
      'Пробежать 42.2 км за один забег';

  @override
  String get achievementTotalDistance10kTitle => 'На дистанции';

  @override
  String get achievementTotalDistance10kDescription =>
      'Пробежать 10 км суммарно';

  @override
  String get achievementTotalDistance50kTitle => 'Дальше больше';

  @override
  String get achievementTotalDistance50kDescription =>
      'Пробежать 50 км суммарно';

  @override
  String get achievementTotalDistance100kTitle => 'Сотня';

  @override
  String get achievementTotalDistance100kDescription =>
      'Пробежать 100 км суммарно';

  @override
  String get achievementTotalDistance250kTitle => 'Длинный путь';

  @override
  String get achievementTotalDistance250kDescription =>
      'Пробежать 250 км суммарно';

  @override
  String get achievementTotalDistance500kTitle => 'Железная выносливость';

  @override
  String get achievementTotalDistance500kDescription =>
      'Пробежать 500 км суммарно';

  @override
  String get achievementSingleCaptureFirstTitle => 'Первый захват';

  @override
  String get achievementSingleCaptureFirstDescription =>
      'Первая пробежка с захватом территории';

  @override
  String get achievementSingleCapture100kTitle => 'Землемер';

  @override
  String get achievementSingleCapture100kDescription =>
      'Захватить 0.1 км² за один забег';

  @override
  String get achievementSingleCapture4mTitle => 'Картограф';

  @override
  String get achievementSingleCapture4mDescription =>
      'Захватить 4 км² за один забег';

  @override
  String get achievementSingleCapture10mTitle => 'Завоеватель';

  @override
  String get achievementSingleCapture10mDescription =>
      'Захватить 10 км² за один забег';

  @override
  String get achievementSingleCapture25mTitle => 'Титан карты';

  @override
  String get achievementSingleCapture25mDescription =>
      'Захватить 25 км² за один забег';

  @override
  String get achievementCaptures005Title => 'Захватчик';

  @override
  String get achievementCaptures005Description =>
      'Выполнить 5 успешных захватов';

  @override
  String get achievementCaptures010Title => 'Охотник за землями';

  @override
  String get achievementCaptures010Description =>
      'Выполнить 10 успешных захватов';

  @override
  String get achievementCaptures025Title => 'Коллекционер территорий';

  @override
  String get achievementCaptures025Description =>
      'Выполнить 25 успешных захватов';

  @override
  String get achievementCaptures050Title => 'Повелитель карты';

  @override
  String get achievementCaptures050Description =>
      'Выполнить 50 успешных захватов';

  @override
  String get achievementTotalCapture10mTitle => 'Империя растёт';

  @override
  String get achievementTotalCapture10mDescription =>
      'Захватить 10 км² суммарно';

  @override
  String get achievementTotalCapture50mTitle => 'Расширение границ';

  @override
  String get achievementTotalCapture50mDescription =>
      'Захватить 50 км² суммарно';

  @override
  String get achievementTotalCapture100mTitle => 'Континентальный размах';

  @override
  String get achievementTotalCapture100mDescription =>
      'Захватить 100 км² суммарно';

  @override
  String get achievementVictimsSingle1Title => 'Первый соперник';

  @override
  String get achievementVictimsSingle1Description =>
      'Захватить территорию хотя бы у 1 соперника за забег';

  @override
  String get achievementVictimsSingle2Title => 'Двойной удар';

  @override
  String get achievementVictimsSingle2Description =>
      'Захватить территорию у 2 соперников за один забег';

  @override
  String get achievementVictimsSingle3Title => 'Тройная угроза';

  @override
  String get achievementVictimsSingle3Description =>
      'Захватить территорию у 3 соперников за один забег';

  @override
  String get achievementVictimsTotal10Title => 'Гроза района';

  @override
  String get achievementVictimsTotal10Description =>
      'Суммарно затронуть 10 соперников';

  @override
  String get achievementVictimsTotal25Title => 'Легенда захватов';

  @override
  String get achievementVictimsTotal25Description =>
      'Суммарно затронуть 25 соперников';

  @override
  String get achievementOwnedArea500kTitle => 'Есть своя земля';

  @override
  String get achievementOwnedArea500kDescription =>
      'Иметь текущую площадь 0.5 км²';

  @override
  String get achievementOwnedArea5mTitle => 'Маленькое королевство';

  @override
  String get achievementOwnedArea5mDescription => 'Иметь текущую площадь 5 км²';

  @override
  String get achievementOwnedArea20mTitle => 'Большая держава';

  @override
  String get achievementOwnedArea20mDescription =>
      'Иметь текущую площадь 20 км²';

  @override
  String get historiesEmpty => 'Пока нет завершенных пробежек.';

  @override
  String get historiesStartedAt => 'Начало';

  @override
  String get historiesEndedAt => 'Завершение';
}
