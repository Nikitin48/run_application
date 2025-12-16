import 'package:flutter/material.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../runs/application/run_tracker_controller.dart';
import '../../../../core/utils/formatters.dart';

class RunControlsCard extends StatelessWidget {
  const RunControlsCard({
    super.key,
    required this.runState,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final RunTrackerState runState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phase = runState.phase;

    final pointsCount = runState.points.length;
    final distanceM = runState.lastFinish?.distanceM ?? 0;

    final title = switch (phase) {
      RunPhase.idle => l10n.runReady,
      RunPhase.running => l10n.runRunning,
      RunPhase.paused => l10n.runPaused,
      RunPhase.finishing => l10n.runFinishing,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  l10n.pointsCount(pointsCount),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (runState.lastFinish != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.runLiveStats(
                  formatMeters(runState.lastFinish!.distanceM),
                  formatAreaM2(runState.lastFinish!.captureAreaM2),
                  '${runState.lastFinish!.victimsCount}',
                ),
              ),
            ] else if (phase != RunPhase.idle) ...[
              const SizedBox(height: 6),
              Text(l10n.runLiveDistanceOnly(formatMeters(distanceM))),
            ],
            if (runState.error != null) ...[
              const SizedBox(height: 6),
              Text(
                runState.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (phase == RunPhase.idle) ...[
                  Expanded(child: FilledButton(onPressed: onStart, child: Text(l10n.runStart))),
                ] else if (phase == RunPhase.running) ...[
                  Expanded(child: FilledButton(onPressed: onPause, child: Text(l10n.runPause))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: onFinish, child: Text(l10n.runFinish))),
                ] else if (phase == RunPhase.paused) ...[
                  Expanded(child: FilledButton(onPressed: onResume, child: Text(l10n.runResume))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: onFinish, child: Text(l10n.runFinish))),
                ] else ...[
                  Expanded(child: FilledButton(onPressed: null, child: Text(l10n.runFinishing))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}


