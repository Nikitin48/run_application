import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Run Application'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerAction;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get switchToLogin;

  /// No description provided for @switchToRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Register'**
  String get switchToRegister;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @historiesTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historiesTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @followOn.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followOn;

  /// No description provided for @followOff.
  ///
  /// In en, this message translates to:
  /// **'Follow me'**
  String get followOff;

  /// No description provided for @testModeOn.
  ///
  /// In en, this message translates to:
  /// **'Test mode on'**
  String get testModeOn;

  /// No description provided for @testModeOff.
  ///
  /// In en, this message translates to:
  /// **'Test mode'**
  String get testModeOff;

  /// No description provided for @territoriesCount.
  ///
  /// In en, this message translates to:
  /// **'Territories: {count}'**
  String territoriesCount(Object count);

  /// No description provided for @territoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load territories'**
  String get territoriesLoadError;

  /// No description provided for @territoryStolenTitle.
  ///
  /// In en, this message translates to:
  /// **'Territory stolen'**
  String get territoryStolenTitle;

  /// No description provided for @territoryStolenMessage.
  ///
  /// In en, this message translates to:
  /// **'You lost {area}'**
  String territoryStolenMessage(Object area);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @runReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get runReady;

  /// No description provided for @runRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get runRunning;

  /// No description provided for @runPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get runPaused;

  /// No description provided for @runFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing…'**
  String get runFinishing;

  /// No description provided for @runStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get runStart;

  /// No description provided for @runPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get runPause;

  /// No description provided for @runResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get runResume;

  /// No description provided for @runFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get runFinish;

  /// No description provided for @pointsCount.
  ///
  /// In en, this message translates to:
  /// **'Points: {count}'**
  String pointsCount(Object count);

  /// No description provided for @runSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Run summary'**
  String get runSummaryTitle;

  /// No description provided for @runSummaryNoData.
  ///
  /// In en, this message translates to:
  /// **'No finished run in memory.'**
  String get runSummaryNoData;

  /// No description provided for @backToMap.
  ///
  /// In en, this message translates to:
  /// **'Back to map'**
  String get backToMap;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get elapsed;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get moving;

  /// No description provided for @avgPaceMoving.
  ///
  /// In en, this message translates to:
  /// **'Avg pace (moving)'**
  String get avgPaceMoving;

  /// No description provided for @capturedArea.
  ///
  /// In en, this message translates to:
  /// **'Captured area'**
  String get capturedArea;

  /// No description provided for @victims.
  ///
  /// In en, this message translates to:
  /// **'Victims'**
  String get victims;

  /// No description provided for @noLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get noLocationYet;

  /// No description provided for @enableLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable location first'**
  String get enableLocationFirst;

  /// No description provided for @runFinished.
  ///
  /// In en, this message translates to:
  /// **'Run finished'**
  String get runFinished;

  /// No description provided for @runLiveStats.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} • Capture: {area} • Victims: {victims}'**
  String runLiveStats(Object area, Object distance, Object victims);

  /// No description provided for @runLiveDistanceOnly.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance}'**
  String runLiveDistanceOnly(Object distance);

  /// No description provided for @runStartingSoon.
  ///
  /// In en, this message translates to:
  /// **'Starting in…'**
  String get runStartingSoon;

  /// No description provided for @profilePersonalSection.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get profilePersonalSection;

  /// No description provided for @profileAvatarUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get profileAvatarUrlLabel;

  /// No description provided for @profileEmailReadonlyHint.
  ///
  /// In en, this message translates to:
  /// **'Email is read-only.'**
  String get profileEmailReadonlyHint;

  /// No description provided for @profileSaveProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSaveProfileAction;

  /// No description provided for @profileTerritoryColorSection.
  ///
  /// In en, this message translates to:
  /// **'Territory color'**
  String get profileTerritoryColorSection;

  /// No description provided for @profileColorCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current color'**
  String get profileColorCurrent;

  /// No description provided for @profilePickCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Pick color'**
  String get profilePickCustomColor;

  /// No description provided for @profileApplyColorAction.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get profileApplyColorAction;

  /// No description provided for @profileSaveColorAction.
  ///
  /// In en, this message translates to:
  /// **'Save color'**
  String get profileSaveColorAction;

  /// No description provided for @profilePasswordSection.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profilePasswordSection;

  /// No description provided for @profileCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPasswordLabel;

  /// No description provided for @profileNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileNewPasswordLabel;

  /// No description provided for @profileConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profileConfirmPasswordLabel;

  /// No description provided for @profileChangePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePasswordAction;

  /// No description provided for @profilePasswordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'New password and confirmation do not match.'**
  String get profilePasswordMismatchError;

  /// No description provided for @profilePasswordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters long.'**
  String get profilePasswordMinLengthError;

  /// No description provided for @profileStatsSection.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get profileStatsSection;

  /// No description provided for @profileRunsCount.
  ///
  /// In en, this message translates to:
  /// **'Runs count'**
  String get profileRunsCount;

  /// No description provided for @profileOwnedArea.
  ///
  /// In en, this message translates to:
  /// **'Current owned area'**
  String get profileOwnedArea;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get profileSaveSuccess;

  /// No description provided for @historiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finished runs yet.'**
  String get historiesEmpty;

  /// No description provided for @historiesStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get historiesStartedAt;

  /// No description provided for @historiesEndedAt.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get historiesEndedAt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
