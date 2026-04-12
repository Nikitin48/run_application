import 'package:flutter/material.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../../core/ui/achievement_badge_card.dart';
import '../../../../core/utils/achievement_localization.dart';
import '../../domain/run_models.dart';

class AchievementsPopup extends StatelessWidget {
  const AchievementsPopup({super.key, required this.finish});

  final FinishRunResponse finish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.achievementsPopupTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                finish.newAchievements.length > 1
                    ? l10n.achievementsPopupIntroMultiple
                    : l10n.achievementsPopupIntroSingle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (finish.levelUp != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primaryContainer.withValues(
                          alpha: 0.82,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.military_tech_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.achievementsLevelUp(
                            finish.levelUp!.oldLevel,
                            finish.levelUp!.newLevel,
                          ),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ...finish.newAchievements.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AchievementBadgeCard(
                    title: localizedAchievementTitle(
                      l10n,
                      code: item.code,
                      fallback: item.title,
                    ),
                    description: localizedAchievementDescription(
                      l10n,
                      code: item.code,
                      fallback: item.description,
                    ),
                    iconKey: item.iconKey,
                    xp: item.xp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Text(
          'Уровень: ${finish.profileLevel}  |  ${finish.profileXp} XP',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.achievementsPopupAction),
        ),
      ],
    );
  }
}
