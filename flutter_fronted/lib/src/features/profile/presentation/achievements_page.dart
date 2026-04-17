import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../app/home_shell_page.dart'
    show kShellBottomBarHeight, shellBottomSystemInset;
import '../../../core/ui/achievement_badge_card.dart';
import '../../../core/utils/achievement_localization.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../application/profile_controller.dart';
import 'widgets/profile_achievements_summary_card.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final achievementsAsync = ref.watch(myAchievementsProvider);
    final bottomClearance =
        kShellBottomBarHeight + shellBottomSystemInset(context) + 24;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsPageTitle)),
      body: achievementsAsync.when(
        data: (overview) {
          final unlockedCount = overview.items
              .where((item) => item.isUnlocked)
              .length;
          if (overview.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.achievementsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myAchievementsProvider);
              await ref.read(myAchievementsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: overview.items.length + 2,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileAchievementsSummaryCard(
                        profileLevel: overview.profileLevel,
                        profileXp: overview.profileXp,
                        unlockedCount: unlockedCount,
                        totalCount: overview.items.length,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          l10n.achievementsPageSubtitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  );
                }
                if (index == overview.items.length + 1) {
                  return SizedBox(height: bottomClearance);
                }
                final item = overview.items[index - 1];
                return AchievementBadgeCard(
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
                  isUnlocked: item.isUnlocked,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.achievementsLoadError(
                toUserFriendlyError(
                  e,
                  fallbackMessage: 'попробуйте снова позже',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
