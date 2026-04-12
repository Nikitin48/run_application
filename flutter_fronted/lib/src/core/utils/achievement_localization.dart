import 'package:run_application/l10n/app_localizations.dart';

String localizedAchievementTitle(
  AppLocalizations l10n, {
  required String code,
  required String fallback,
}) {
  switch (code) {
    case 'runs_001':
      return l10n.achievementRuns001Title;
    case 'runs_005':
      return l10n.achievementRuns005Title;
    case 'runs_010':
      return l10n.achievementRuns010Title;
    case 'runs_025':
      return l10n.achievementRuns025Title;
    case 'runs_050':
      return l10n.achievementRuns050Title;
    case 'single_distance_1k':
      return l10n.achievementSingleDistance1kTitle;
    case 'single_distance_5k':
      return l10n.achievementSingleDistance5kTitle;
    case 'single_distance_10k':
      return l10n.achievementSingleDistance10kTitle;
    case 'single_distance_21k':
      return l10n.achievementSingleDistance21kTitle;
    case 'single_distance_42k':
      return l10n.achievementSingleDistance42kTitle;
    case 'total_distance_10k':
      return l10n.achievementTotalDistance10kTitle;
    case 'total_distance_50k':
      return l10n.achievementTotalDistance50kTitle;
    case 'total_distance_100k':
      return l10n.achievementTotalDistance100kTitle;
    case 'total_distance_250k':
      return l10n.achievementTotalDistance250kTitle;
    case 'total_distance_500k':
      return l10n.achievementTotalDistance500kTitle;
    case 'single_capture_first':
      return l10n.achievementSingleCaptureFirstTitle;
    case 'single_capture_100k':
      return l10n.achievementSingleCapture100kTitle;
    case 'single_capture_4m':
      return l10n.achievementSingleCapture4mTitle;
    case 'single_capture_10m':
      return l10n.achievementSingleCapture10mTitle;
    case 'single_capture_25m':
      return l10n.achievementSingleCapture25mTitle;
    case 'captures_005':
      return l10n.achievementCaptures005Title;
    case 'captures_010':
      return l10n.achievementCaptures010Title;
    case 'captures_025':
      return l10n.achievementCaptures025Title;
    case 'captures_050':
      return l10n.achievementCaptures050Title;
    case 'total_capture_10m':
      return l10n.achievementTotalCapture10mTitle;
    case 'total_capture_50m':
      return l10n.achievementTotalCapture50mTitle;
    case 'total_capture_100m':
      return l10n.achievementTotalCapture100mTitle;
    case 'victims_single_1':
      return l10n.achievementVictimsSingle1Title;
    case 'victims_single_2':
      return l10n.achievementVictimsSingle2Title;
    case 'victims_single_3':
      return l10n.achievementVictimsSingle3Title;
    case 'victims_total_10':
      return l10n.achievementVictimsTotal10Title;
    case 'victims_total_25':
      return l10n.achievementVictimsTotal25Title;
    case 'owned_area_500k':
      return l10n.achievementOwnedArea500kTitle;
    case 'owned_area_5m':
      return l10n.achievementOwnedArea5mTitle;
    case 'owned_area_20m':
      return l10n.achievementOwnedArea20mTitle;
    default:
      return fallback;
  }
}

String localizedAchievementDescription(
  AppLocalizations l10n, {
  required String code,
  required String fallback,
}) {
  switch (code) {
    case 'runs_001':
      return l10n.achievementRuns001Description;
    case 'runs_005':
      return l10n.achievementRuns005Description;
    case 'runs_010':
      return l10n.achievementRuns010Description;
    case 'runs_025':
      return l10n.achievementRuns025Description;
    case 'runs_050':
      return l10n.achievementRuns050Description;
    case 'single_distance_1k':
      return l10n.achievementSingleDistance1kDescription;
    case 'single_distance_5k':
      return l10n.achievementSingleDistance5kDescription;
    case 'single_distance_10k':
      return l10n.achievementSingleDistance10kDescription;
    case 'single_distance_21k':
      return l10n.achievementSingleDistance21kDescription;
    case 'single_distance_42k':
      return l10n.achievementSingleDistance42kDescription;
    case 'total_distance_10k':
      return l10n.achievementTotalDistance10kDescription;
    case 'total_distance_50k':
      return l10n.achievementTotalDistance50kDescription;
    case 'total_distance_100k':
      return l10n.achievementTotalDistance100kDescription;
    case 'total_distance_250k':
      return l10n.achievementTotalDistance250kDescription;
    case 'total_distance_500k':
      return l10n.achievementTotalDistance500kDescription;
    case 'single_capture_first':
      return l10n.achievementSingleCaptureFirstDescription;
    case 'single_capture_100k':
      return l10n.achievementSingleCapture100kDescription;
    case 'single_capture_4m':
      return l10n.achievementSingleCapture4mDescription;
    case 'single_capture_10m':
      return l10n.achievementSingleCapture10mDescription;
    case 'single_capture_25m':
      return l10n.achievementSingleCapture25mDescription;
    case 'captures_005':
      return l10n.achievementCaptures005Description;
    case 'captures_010':
      return l10n.achievementCaptures010Description;
    case 'captures_025':
      return l10n.achievementCaptures025Description;
    case 'captures_050':
      return l10n.achievementCaptures050Description;
    case 'total_capture_10m':
      return l10n.achievementTotalCapture10mDescription;
    case 'total_capture_50m':
      return l10n.achievementTotalCapture50mDescription;
    case 'total_capture_100m':
      return l10n.achievementTotalCapture100mDescription;
    case 'victims_single_1':
      return l10n.achievementVictimsSingle1Description;
    case 'victims_single_2':
      return l10n.achievementVictimsSingle2Description;
    case 'victims_single_3':
      return l10n.achievementVictimsSingle3Description;
    case 'victims_total_10':
      return l10n.achievementVictimsTotal10Description;
    case 'victims_total_25':
      return l10n.achievementVictimsTotal25Description;
    case 'owned_area_500k':
      return l10n.achievementOwnedArea500kDescription;
    case 'owned_area_5m':
      return l10n.achievementOwnedArea5mDescription;
    case 'owned_area_20m':
      return l10n.achievementOwnedArea20mDescription;
    default:
      return fallback;
  }
}
