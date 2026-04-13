import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../application/run_tracker_controller.dart';
import '../../../core/utils/formatters.dart';
import 'widgets/achievements_popup.dart';

class RunSummaryPage extends ConsumerStatefulWidget {
  const RunSummaryPage({super.key});

  @override
  ConsumerState<RunSummaryPage> createState() => _RunSummaryPageState();
}

class _RunSummaryPageState extends ConsumerState<RunSummaryPage> {
  bool _didShowAchievementsPopup = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final finish = ref.watch(runTrackerProvider).lastFinish;

    if (!_didShowAchievementsPopup &&
        finish != null &&
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: finish == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.runSummaryNoData),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/map'),
                    child: Text(l10n.backToMap),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetricRow(
                    label: l10n.distance,
                    value: formatMeters(finish.distanceM),
                  ),
                  _MetricRow(
                    label: l10n.elapsed,
                    value: formatDurationMmSs(finish.elapsedS),
                  ),
                  _MetricRow(
                    label: l10n.paused,
                    value: formatDurationMmSs(finish.pausedS),
                  ),
                  _MetricRow(
                    label: l10n.moving,
                    value: formatDurationMmSs(finish.movingS),
                  ),
                  _MetricRow(
                    label: l10n.avgPaceMoving,
                    value: formatPace(
                      distanceM: finish.distanceM,
                      movingS: finish.movingS,
                    ),
                  ),
                  const Divider(height: 32),
                  _MetricRow(
                    label: l10n.capturedArea,
                    value: formatAreaM2(finish.captureAreaM2),
                  ),
                  _MetricRow(
                    label: l10n.victims,
                    value: '${finish.victimsCount}',
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      ref.read(runTrackerProvider.notifier).clearLastFinish();
                      context.go('/map');
                    },
                    child: Text(l10n.done),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
