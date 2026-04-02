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
  String get capturedArea => 'Захваченная площадь';

  @override
  String get victims => 'Отжато у пользователей';

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
  String get historiesEmpty => 'Пока нет завершенных пробежек.';

  @override
  String get historiesStartedAt => 'Начало';

  @override
  String get historiesEndedAt => 'Завершение';
}
