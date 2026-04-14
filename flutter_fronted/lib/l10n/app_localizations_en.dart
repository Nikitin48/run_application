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
  String get appBootstrapping => 'Preparing app…';

  @override
  String get authValidationEmailInvalid => 'Enter a valid email address.';

  @override
  String get authValidationPasswordMinLength =>
      'Password must be at least 8 characters.';

  @override
  String get authInvalidCredentials => 'Invalid email or password';

  @override
  String get authLegalNotice => 'By continuing, you accept the service terms.';

  @override
  String get authPrivacyPolicyAction => 'Privacy policy';

  @override
  String get authTermsOfUseAction => 'Terms of use';

  @override
  String get mapTitle => 'Map';

  @override
  String get historiesTitle => 'History';

  @override
  String get profileTitle => 'Profile';

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

  @override
  String get runStartingSoon => 'Starting in…';

  @override
  String get profilePersonalSection => 'Personal data';

  @override
  String get profileAvatarUrlLabel => 'Avatar URL';

  @override
  String get profileUploadAvatarAction => 'Choose photo';

  @override
  String get profileDeleteAvatarAction => 'Delete avatar';

  @override
  String get profileAvatarUploadSuccess => 'Avatar updated';

  @override
  String get profileAvatarDeleteSuccess => 'Avatar removed';

  @override
  String get profileEmailReadonlyHint => 'Email is read-only.';

  @override
  String get profileSaveProfileAction => 'Save profile';

  @override
  String get profileTerritoryColorSection => 'Territory color';

  @override
  String get profileColorCurrent => 'Current color';

  @override
  String get profilePickCustomColor => 'Pick color';

  @override
  String get profileApplyColorAction => 'Apply';

  @override
  String get profileSaveColorAction => 'Save color';

  @override
  String get profilePasswordSection => 'Change password';

  @override
  String get profileCurrentPasswordLabel => 'Current password';

  @override
  String get profileNewPasswordLabel => 'New password';

  @override
  String get profileConfirmPasswordLabel => 'Confirm new password';

  @override
  String get profileChangePasswordAction => 'Change password';

  @override
  String get profilePasswordChangedSuccess => 'Password changed successfully';

  @override
  String get profilePasswordMismatchError =>
      'New password and confirmation do not match.';

  @override
  String get profilePasswordMinLengthError =>
      'New password must be at least 8 characters long.';

  @override
  String get profileStatsSection => 'Stats';

  @override
  String get profileRunsCount => 'Runs count';

  @override
  String get profileOwnedArea => 'Current owned area';

  @override
  String get profileSaveSuccess => 'Changes saved';

  @override
  String get profileLevelLabel => 'Profile level';

  @override
  String get profileXpLabel => 'Profile XP';

  @override
  String get profileSuccessfulCapturesLabel => 'Successful captures';

  @override
  String get profileTotalCapturedLabel => 'Total captured';

  @override
  String get profileTotalVictimsLabel => 'Total opponents affected';

  @override
  String get achievementsPopupTitle => 'New achievements';

  @override
  String get achievementsPopupIntroSingle =>
      'You unlocked a new reward on this run.';

  @override
  String get achievementsPopupIntroMultiple =>
      'You unlocked several rewards on this run.';

  @override
  String get achievementsPopupAction => 'Nice';

  @override
  String achievementsLevelUp(Object oldLevel, Object newLevel) {
    return 'Level up: $oldLevel -> $newLevel';
  }

  @override
  String get achievementsCollectionTitle => 'Achievement collection';

  @override
  String achievementsCollectionSummary(Object count, Object level, Object xp) {
    return 'Unlocked $count | Level $level | $xp XP';
  }

  @override
  String get achievementsOpenAllAction => 'All achievements';

  @override
  String get achievementsEmpty =>
      'No achievements unlocked yet. Finish runs and capture territory to start your collection.';

  @override
  String achievementsLoadError(Object error) {
    return 'Failed to load achievements: $error';
  }

  @override
  String get achievementsPageTitle => 'All achievements';

  @override
  String get achievementsPageSubtitle =>
      'Your unlocked rewards and profile progress';

  @override
  String get achievementTierBase => 'Basic';

  @override
  String get achievementTierAdvanced => 'Advanced';

  @override
  String get achievementTierRare => 'Rare';

  @override
  String get achievementTierLegendary => 'Legendary';

  @override
  String get achievementRuns001Title => 'First steps';

  @override
  String get achievementRuns001Description => 'Finish 1 run';

  @override
  String get achievementRuns005Title => 'Warm-up';

  @override
  String get achievementRuns005Description => 'Finish 5 runs';

  @override
  String get achievementRuns010Title => 'In rhythm';

  @override
  String get achievementRuns010Description => 'Finish 10 runs';

  @override
  String get achievementRuns025Title => 'Unstoppable';

  @override
  String get achievementRuns025Description => 'Finish 25 runs';

  @override
  String get achievementRuns050Title => 'Running machine';

  @override
  String get achievementRuns050Description => 'Finish 50 runs';

  @override
  String get achievementSingleDistance1kTitle => 'First kilometer';

  @override
  String get achievementSingleDistance1kDescription =>
      'Run 1 km in a single run';

  @override
  String get achievementSingleDistance5kTitle => 'Five k';

  @override
  String get achievementSingleDistance5kDescription =>
      'Run 5 km in a single run';

  @override
  String get achievementSingleDistance10kTitle => 'Ten k';

  @override
  String get achievementSingleDistance10kDescription =>
      'Run 10 km in a single run';

  @override
  String get achievementSingleDistance21kTitle => 'Half marathoner';

  @override
  String get achievementSingleDistance21kDescription =>
      'Run 21.1 km in a single run';

  @override
  String get achievementSingleDistance42kTitle => 'Marathoner';

  @override
  String get achievementSingleDistance42kDescription =>
      'Run 42.2 km in a single run';

  @override
  String get achievementTotalDistance10kTitle => 'On the move';

  @override
  String get achievementTotalDistance10kDescription => 'Run 10 km total';

  @override
  String get achievementTotalDistance50kTitle => 'Further and further';

  @override
  String get achievementTotalDistance50kDescription => 'Run 50 km total';

  @override
  String get achievementTotalDistance100kTitle => 'One hundred';

  @override
  String get achievementTotalDistance100kDescription => 'Run 100 km total';

  @override
  String get achievementTotalDistance250kTitle => 'Long road';

  @override
  String get achievementTotalDistance250kDescription => 'Run 250 km total';

  @override
  String get achievementTotalDistance500kTitle => 'Iron endurance';

  @override
  String get achievementTotalDistance500kDescription => 'Run 500 km total';

  @override
  String get achievementSingleCaptureFirstTitle => 'First capture';

  @override
  String get achievementSingleCaptureFirstDescription =>
      'Your first run with captured territory';

  @override
  String get achievementSingleCapture100kTitle => 'Surveyor';

  @override
  String get achievementSingleCapture100kDescription =>
      'Capture 0.1 km² in one run';

  @override
  String get achievementSingleCapture4mTitle => 'Cartographer';

  @override
  String get achievementSingleCapture4mDescription =>
      'Capture 4 km² in one run';

  @override
  String get achievementSingleCapture10mTitle => 'Conqueror';

  @override
  String get achievementSingleCapture10mDescription =>
      'Capture 10 km² in one run';

  @override
  String get achievementSingleCapture25mTitle => 'Map titan';

  @override
  String get achievementSingleCapture25mDescription =>
      'Capture 25 km² in one run';

  @override
  String get achievementCaptures005Title => 'Capturer';

  @override
  String get achievementCaptures005Description =>
      'Complete 5 successful captures';

  @override
  String get achievementCaptures010Title => 'Land hunter';

  @override
  String get achievementCaptures010Description =>
      'Complete 10 successful captures';

  @override
  String get achievementCaptures025Title => 'Territory collector';

  @override
  String get achievementCaptures025Description =>
      'Complete 25 successful captures';

  @override
  String get achievementCaptures050Title => 'Lord of the map';

  @override
  String get achievementCaptures050Description =>
      'Complete 50 successful captures';

  @override
  String get achievementTotalCapture10mTitle => 'Empire grows';

  @override
  String get achievementTotalCapture10mDescription => 'Capture 10 km² total';

  @override
  String get achievementTotalCapture50mTitle => 'Expanding borders';

  @override
  String get achievementTotalCapture50mDescription => 'Capture 50 km² total';

  @override
  String get achievementTotalCapture100mTitle => 'Continental scale';

  @override
  String get achievementTotalCapture100mDescription => 'Capture 100 km² total';

  @override
  String get achievementVictimsSingle1Title => 'First rival';

  @override
  String get achievementVictimsSingle1Description =>
      'Capture territory from at least 1 rival in a run';

  @override
  String get achievementVictimsSingle2Title => 'Double strike';

  @override
  String get achievementVictimsSingle2Description =>
      'Capture territory from 2 rivals in one run';

  @override
  String get achievementVictimsSingle3Title => 'Triple threat';

  @override
  String get achievementVictimsSingle3Description =>
      'Capture territory from 3 rivals in one run';

  @override
  String get achievementVictimsTotal10Title => 'District menace';

  @override
  String get achievementVictimsTotal10Description => 'Affect 10 rivals total';

  @override
  String get achievementVictimsTotal25Title => 'Capture legend';

  @override
  String get achievementVictimsTotal25Description => 'Affect 25 rivals total';

  @override
  String get achievementOwnedArea500kTitle => 'Landowner';

  @override
  String get achievementOwnedArea500kDescription =>
      'Own 0.5 km² of current territory';

  @override
  String get achievementOwnedArea5mTitle => 'Little kingdom';

  @override
  String get achievementOwnedArea5mDescription =>
      'Own 5 km² of current territory';

  @override
  String get achievementOwnedArea20mTitle => 'Great power';

  @override
  String get achievementOwnedArea20mDescription =>
      'Own 20 km² of current territory';

  @override
  String get historiesEmpty => 'No finished runs yet.';

  @override
  String get historiesStartedAt => 'Started';

  @override
  String get historiesEndedAt => 'Finished';
}
