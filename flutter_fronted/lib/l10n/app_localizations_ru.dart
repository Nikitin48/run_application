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
  String get mapTitle => 'Карта';

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
}
