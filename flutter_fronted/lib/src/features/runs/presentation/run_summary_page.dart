import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../application/run_tracker_controller.dart';
import 'widgets/achievements_popup.dart';
import 'widgets/run_stats_card.dart';

class RunSummaryPage extends ConsumerStatefulWidget {
  const RunSummaryPage({super.key});

  @override
  ConsumerState<RunSummaryPage> createState() => _RunSummaryPageState();
}

class _RunSummaryPageState extends ConsumerState<RunSummaryPage> {
  bool _didShowAchievementsPopup = false;
  bool _didRedirectToMap = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final finish = ref.watch(runTrackerProvider).lastFinish;

    if (finish == null) {
      if (!_didRedirectToMap) {
        _didRedirectToMap = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/map');
        });
      }
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_didShowAchievementsPopup &&
        (finish.newAchievements.isNotEmpty || finish.levelUp != null)) {
      _didShowAchievementsPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => AchievementsPopup(finish: finish),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runSummaryTitle),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RunStatsCard(
              startedAt: finish.startedAt,
              endedAt: finish.endedAt,
              capturePolygons: finish.capturePolygons,
              trackPoints: finish.trackPoints,
              previewAccent: Theme.of(context).colorScheme.primary,
              distanceM: finish.distanceM,
              elapsedS: finish.elapsedS,
              pausedS: finish.pausedS,
              movingS: finish.movingS,
              captureAreaM2: finish.captureAreaM2,
              victimsCount: finish.victimsCount,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.go('/map');
                  ref.read(runTrackerProvider.notifier).clearLastFinish();
                },
                child: Text(l10n.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
