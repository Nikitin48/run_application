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

  /// No description provided for @appBootstrapping.
  ///
  /// In en, this message translates to:
  /// **'Preparing app…'**
  String get appBootstrapping;

  /// No description provided for @authValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authValidationEmailInvalid;

  /// No description provided for @authValidationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authValidationPasswordMinLength;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authInvalidCredentials;

  /// No description provided for @authLegalNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept the service terms.'**
  String get authLegalNotice;

  /// No description provided for @authPrivacyPolicyAction.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get authPrivacyPolicyAction;

  /// No description provided for @authTermsOfUseAction.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get authTermsOfUseAction;

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

  /// No description provided for @profileUploadAvatarAction.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get profileUploadAvatarAction;

  /// No description provided for @profileDeleteAvatarAction.
  ///
  /// In en, this message translates to:
  /// **'Delete avatar'**
  String get profileDeleteAvatarAction;

  /// No description provided for @profileAvatarUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get profileAvatarUploadSuccess;

  /// No description provided for @profileAvatarDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Avatar removed'**
  String get profileAvatarDeleteSuccess;

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

  /// No description provided for @profilePasswordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get profilePasswordChangedSuccess;

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

  /// No description provided for @profileLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile level'**
  String get profileLevelLabel;

  /// No description provided for @profileXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile XP'**
  String get profileXpLabel;

  /// No description provided for @profileSuccessfulCapturesLabel.
  ///
  /// In en, this message translates to:
  /// **'Successful captures'**
  String get profileSuccessfulCapturesLabel;

  /// No description provided for @profileTotalCapturedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total captured'**
  String get profileTotalCapturedLabel;

  /// No description provided for @profileTotalVictimsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total opponents affected'**
  String get profileTotalVictimsLabel;

  /// No description provided for @achievementsPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'New achievements'**
  String get achievementsPopupTitle;

  /// No description provided for @achievementsPopupIntroSingle.
  ///
  /// In en, this message translates to:
  /// **'You unlocked a new reward on this run.'**
  String get achievementsPopupIntroSingle;

  /// No description provided for @achievementsPopupIntroMultiple.
  ///
  /// In en, this message translates to:
  /// **'You unlocked several rewards on this run.'**
  String get achievementsPopupIntroMultiple;

  /// No description provided for @achievementsPopupAction.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get achievementsPopupAction;

  /// No description provided for @achievementsLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up: {oldLevel} -> {newLevel}'**
  String achievementsLevelUp(Object oldLevel, Object newLevel);

  /// No description provided for @achievementsCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement collection'**
  String get achievementsCollectionTitle;

  /// No description provided for @achievementsCollectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Unlocked {count} | Level {level} | {xp} XP'**
  String achievementsCollectionSummary(Object count, Object level, Object xp);

  /// No description provided for @achievementsOpenAllAction.
  ///
  /// In en, this message translates to:
  /// **'All achievements'**
  String get achievementsOpenAllAction;

  /// No description provided for @achievementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No achievements unlocked yet. Finish runs and capture territory to start your collection.'**
  String get achievementsEmpty;

  /// No description provided for @achievementsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load achievements: {error}'**
  String achievementsLoadError(Object error);

  /// No description provided for @achievementsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'All achievements'**
  String get achievementsPageTitle;

  /// No description provided for @achievementsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your unlocked rewards and profile progress'**
  String get achievementsPageSubtitle;

  /// No description provided for @achievementTierBase.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get achievementTierBase;

  /// No description provided for @achievementTierAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get achievementTierAdvanced;

  /// No description provided for @achievementTierRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get achievementTierRare;

  /// No description provided for @achievementTierLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get achievementTierLegendary;

  /// No description provided for @achievementRuns001Title.
  ///
  /// In en, this message translates to:
  /// **'First steps'**
  String get achievementRuns001Title;

  /// No description provided for @achievementRuns001Description.
  ///
  /// In en, this message translates to:
  /// **'Finish 1 run'**
  String get achievementRuns001Description;

  /// No description provided for @achievementRuns005Title.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get achievementRuns005Title;

  /// No description provided for @achievementRuns005Description.
  ///
  /// In en, this message translates to:
  /// **'Finish 5 runs'**
  String get achievementRuns005Description;

  /// No description provided for @achievementRuns010Title.
  ///
  /// In en, this message translates to:
  /// **'In rhythm'**
  String get achievementRuns010Title;

  /// No description provided for @achievementRuns010Description.
  ///
  /// In en, this message translates to:
  /// **'Finish 10 runs'**
  String get achievementRuns010Description;

  /// No description provided for @achievementRuns025Title.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get achievementRuns025Title;

  /// No description provided for @achievementRuns025Description.
  ///
  /// In en, this message translates to:
  /// **'Finish 25 runs'**
  String get achievementRuns025Description;

  /// No description provided for @achievementRuns050Title.
  ///
  /// In en, this message translates to:
  /// **'Running machine'**
  String get achievementRuns050Title;

  /// No description provided for @achievementRuns050Description.
  ///
  /// In en, this message translates to:
  /// **'Finish 50 runs'**
  String get achievementRuns050Description;

  /// No description provided for @achievementSingleDistance1kTitle.
  ///
  /// In en, this message translates to:
  /// **'First kilometer'**
  String get achievementSingleDistance1kTitle;

  /// No description provided for @achievementSingleDistance1kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 1 km in a single run'**
  String get achievementSingleDistance1kDescription;

  /// No description provided for @achievementSingleDistance5kTitle.
  ///
  /// In en, this message translates to:
  /// **'Five k'**
  String get achievementSingleDistance5kTitle;

  /// No description provided for @achievementSingleDistance5kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 5 km in a single run'**
  String get achievementSingleDistance5kDescription;

  /// No description provided for @achievementSingleDistance10kTitle.
  ///
  /// In en, this message translates to:
  /// **'Ten k'**
  String get achievementSingleDistance10kTitle;

  /// No description provided for @achievementSingleDistance10kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 10 km in a single run'**
  String get achievementSingleDistance10kDescription;

  /// No description provided for @achievementSingleDistance21kTitle.
  ///
  /// In en, this message translates to:
  /// **'Half marathoner'**
  String get achievementSingleDistance21kTitle;

  /// No description provided for @achievementSingleDistance21kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 21.1 km in a single run'**
  String get achievementSingleDistance21kDescription;

  /// No description provided for @achievementSingleDistance42kTitle.
  ///
  /// In en, this message translates to:
  /// **'Marathoner'**
  String get achievementSingleDistance42kTitle;

  /// No description provided for @achievementSingleDistance42kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 42.2 km in a single run'**
  String get achievementSingleDistance42kDescription;

  /// No description provided for @achievementTotalDistance10kTitle.
  ///
  /// In en, this message translates to:
  /// **'On the move'**
  String get achievementTotalDistance10kTitle;

  /// No description provided for @achievementTotalDistance10kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 10 km total'**
  String get achievementTotalDistance10kDescription;

  /// No description provided for @achievementTotalDistance50kTitle.
  ///
  /// In en, this message translates to:
  /// **'Further and further'**
  String get achievementTotalDistance50kTitle;

  /// No description provided for @achievementTotalDistance50kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 50 km total'**
  String get achievementTotalDistance50kDescription;

  /// No description provided for @achievementTotalDistance100kTitle.
  ///
  /// In en, this message translates to:
  /// **'One hundred'**
  String get achievementTotalDistance100kTitle;

  /// No description provided for @achievementTotalDistance100kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 100 km total'**
  String get achievementTotalDistance100kDescription;

  /// No description provided for @achievementTotalDistance250kTitle.
  ///
  /// In en, this message translates to:
  /// **'Long road'**
  String get achievementTotalDistance250kTitle;

  /// No description provided for @achievementTotalDistance250kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 250 km total'**
  String get achievementTotalDistance250kDescription;

  /// No description provided for @achievementTotalDistance500kTitle.
  ///
  /// In en, this message translates to:
  /// **'Iron endurance'**
  String get achievementTotalDistance500kTitle;

  /// No description provided for @achievementTotalDistance500kDescription.
  ///
  /// In en, this message translates to:
  /// **'Run 500 km total'**
  String get achievementTotalDistance500kDescription;

  /// No description provided for @achievementSingleCaptureFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'First capture'**
  String get achievementSingleCaptureFirstTitle;

  /// No description provided for @achievementSingleCaptureFirstDescription.
  ///
  /// In en, this message translates to:
  /// **'Your first run with captured territory'**
  String get achievementSingleCaptureFirstDescription;

  /// No description provided for @achievementSingleCapture100kTitle.
  ///
  /// In en, this message translates to:
  /// **'Surveyor'**
  String get achievementSingleCapture100kTitle;

  /// No description provided for @achievementSingleCapture100kDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 0.1 km² in one run'**
  String get achievementSingleCapture100kDescription;

  /// No description provided for @achievementSingleCapture4mTitle.
  ///
  /// In en, this message translates to:
  /// **'Cartographer'**
  String get achievementSingleCapture4mTitle;

  /// No description provided for @achievementSingleCapture4mDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 4 km² in one run'**
  String get achievementSingleCapture4mDescription;

  /// No description provided for @achievementSingleCapture10mTitle.
  ///
  /// In en, this message translates to:
  /// **'Conqueror'**
  String get achievementSingleCapture10mTitle;

  /// No description provided for @achievementSingleCapture10mDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 10 km² in one run'**
  String get achievementSingleCapture10mDescription;

  /// No description provided for @achievementSingleCapture25mTitle.
  ///
  /// In en, this message translates to:
  /// **'Map titan'**
  String get achievementSingleCapture25mTitle;

  /// No description provided for @achievementSingleCapture25mDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 25 km² in one run'**
  String get achievementSingleCapture25mDescription;

  /// No description provided for @achievementCaptures005Title.
  ///
  /// In en, this message translates to:
  /// **'Capturer'**
  String get achievementCaptures005Title;

  /// No description provided for @achievementCaptures005Description.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 successful captures'**
  String get achievementCaptures005Description;

  /// No description provided for @achievementCaptures010Title.
  ///
  /// In en, this message translates to:
  /// **'Land hunter'**
  String get achievementCaptures010Title;

  /// No description provided for @achievementCaptures010Description.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 successful captures'**
  String get achievementCaptures010Description;

  /// No description provided for @achievementCaptures025Title.
  ///
  /// In en, this message translates to:
  /// **'Territory collector'**
  String get achievementCaptures025Title;

  /// No description provided for @achievementCaptures025Description.
  ///
  /// In en, this message translates to:
  /// **'Complete 25 successful captures'**
  String get achievementCaptures025Description;

  /// No description provided for @achievementCaptures050Title.
  ///
  /// In en, this message translates to:
  /// **'Lord of the map'**
  String get achievementCaptures050Title;

  /// No description provided for @achievementCaptures050Description.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 successful captures'**
  String get achievementCaptures050Description;

  /// No description provided for @achievementTotalCapture10mTitle.
  ///
  /// In en, this message translates to:
  /// **'Empire grows'**
  String get achievementTotalCapture10mTitle;

  /// No description provided for @achievementTotalCapture10mDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 10 km² total'**
  String get achievementTotalCapture10mDescription;

  /// No description provided for @achievementTotalCapture50mTitle.
  ///
  /// In en, this message translates to:
  /// **'Expanding borders'**
  String get achievementTotalCapture50mTitle;

  /// No description provided for @achievementTotalCapture50mDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 50 km² total'**
  String get achievementTotalCapture50mDescription;

  /// No description provided for @achievementTotalCapture100mTitle.
  ///
  /// In en, this message translates to:
  /// **'Continental scale'**
  String get achievementTotalCapture100mTitle;

  /// No description provided for @achievementTotalCapture100mDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 100 km² total'**
  String get achievementTotalCapture100mDescription;

  /// No description provided for @achievementVictimsSingle1Title.
  ///
  /// In en, this message translates to:
  /// **'First rival'**
  String get achievementVictimsSingle1Title;

  /// No description provided for @achievementVictimsSingle1Description.
  ///
  /// In en, this message translates to:
  /// **'Capture territory from at least 1 rival in a run'**
  String get achievementVictimsSingle1Description;

  /// No description provided for @achievementVictimsSingle2Title.
  ///
  /// In en, this message translates to:
  /// **'Double strike'**
  String get achievementVictimsSingle2Title;

  /// No description provided for @achievementVictimsSingle2Description.
  ///
  /// In en, this message translates to:
  /// **'Capture territory from 2 rivals in one run'**
  String get achievementVictimsSingle2Description;

  /// No description provided for @achievementVictimsSingle3Title.
  ///
  /// In en, this message translates to:
  /// **'Triple threat'**
  String get achievementVictimsSingle3Title;

  /// No description provided for @achievementVictimsSingle3Description.
  ///
  /// In en, this message translates to:
  /// **'Capture territory from 3 rivals in one run'**
  String get achievementVictimsSingle3Description;

  /// No description provided for @achievementVictimsTotal10Title.
  ///
  /// In en, this message translates to:
  /// **'District menace'**
  String get achievementVictimsTotal10Title;

  /// No description provided for @achievementVictimsTotal10Description.
  ///
  /// In en, this message translates to:
  /// **'Affect 10 rivals total'**
  String get achievementVictimsTotal10Description;

  /// No description provided for @achievementVictimsTotal25Title.
  ///
  /// In en, this message translates to:
  /// **'Capture legend'**
  String get achievementVictimsTotal25Title;

  /// No description provided for @achievementVictimsTotal25Description.
  ///
  /// In en, this message translates to:
  /// **'Affect 25 rivals total'**
  String get achievementVictimsTotal25Description;

  /// No description provided for @achievementOwnedArea500kTitle.
  ///
  /// In en, this message translates to:
  /// **'Landowner'**
  String get achievementOwnedArea500kTitle;

  /// No description provided for @achievementOwnedArea500kDescription.
  ///
  /// In en, this message translates to:
  /// **'Own 0.5 km² of current territory'**
  String get achievementOwnedArea500kDescription;

  /// No description provided for @achievementOwnedArea5mTitle.
  ///
  /// In en, this message translates to:
  /// **'Little kingdom'**
  String get achievementOwnedArea5mTitle;

  /// No description provided for @achievementOwnedArea5mDescription.
  ///
  /// In en, this message translates to:
  /// **'Own 5 km² of current territory'**
  String get achievementOwnedArea5mDescription;

  /// No description provided for @achievementOwnedArea20mTitle.
  ///
  /// In en, this message translates to:
  /// **'Great power'**
  String get achievementOwnedArea20mTitle;

  /// No description provided for @achievementOwnedArea20mDescription.
  ///
  /// In en, this message translates to:
  /// **'Own 20 km² of current territory'**
  String get achievementOwnedArea20mDescription;

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
