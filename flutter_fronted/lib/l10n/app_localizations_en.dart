// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Run Application';

  @override
  String get loginTitle => 'Login';

  @override
  String get registerTitle => 'Register';

  @override
  String get emailLabel => 'Email';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginAction => 'Login';

  @override
  String get registerAction => 'Create account';

  @override
  String get switchToLogin => 'Already have an account? Login';

  @override
  String get switchToRegister => 'No account? Register';

  @override
  String get loading => 'Loading…';

  @override
  String get mapTitle => 'Map';

  @override
  String get logout => 'Logout';

  @override
  String get followOn => 'Following';

  @override
  String get followOff => 'Follow me';

  @override
  String get testModeOn => 'Test mode on';

  @override
  String get testModeOff => 'Test mode';

  @override
  String territoriesCount(Object count) {
    return 'Territories: $count';
  }

  @override
  String get territoriesLoadError => 'Failed to load territories';

  @override
  String get territoryStolenTitle => 'Territory stolen';

  @override
  String territoryStolenMessage(Object area) {
    return 'You lost $area';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get close => 'Close';

  @override
  String get runReady => 'Ready';

  @override
  String get runRunning => 'Running';

  @override
  String get runPaused => 'Paused';

  @override
  String get runFinishing => 'Finishing…';

  @override
  String get runStart => 'Start';

  @override
  String get runPause => 'Pause';

  @override
  String get runResume => 'Resume';

  @override
  String get runFinish => 'Finish';

  @override
  String pointsCount(Object count) {
    return 'Points: $count';
  }

  @override
  String get runSummaryTitle => 'Run summary';

  @override
  String get runSummaryNoData => 'No finished run in memory.';

  @override
  String get backToMap => 'Back to map';

  @override
  String get done => 'Done';

  @override
  String get distance => 'Distance';

  @override
  String get elapsed => 'Elapsed';

  @override
  String get paused => 'Paused';

  @override
  String get moving => 'Moving';

  @override
  String get avgPaceMoving => 'Avg pace (moving)';

  @override
  String get capturedArea => 'Captured area';

  @override
  String get victims => 'Victims';

  @override
  String get noLocationYet => 'No location yet';

  @override
  String get enableLocationFirst => 'Enable location first';

  @override
  String get runFinished => 'Run finished';

  @override
  String runLiveStats(Object area, Object distance, Object victims) {
    return 'Distance: $distance • Capture: $area • Victims: $victims';
  }

  @override
  String runLiveDistanceOnly(Object distance) {
    return 'Distance: $distance';
  }
}
