import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../core/utils/formatters.dart';
import '../../runs/domain/run_models.dart';
import '../application/run_history_provider.dart';

class HistoriesPage extends ConsumerWidget {
  const HistoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(runHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historiesTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(runHistoryProvider);
          await ref.read(runHistoryProvider.future);
        },
        child: historyAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.historiesEmpty),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _RunHistoryCard(item: items[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunHistoryCard extends StatelessWidget {
  const _RunHistoryCard({required this.item});

  final RunHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startedLabel = _formatDateTime(item.startedAt) ?? '—';
    final endedLabel = _formatDateTime(item.endedAt) ?? '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.historiesStartedAt}: $startedLabel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.historiesEndedAt}: $endedLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            _MetricRow(
              label: l10n.distance,
              value: formatMeters(item.distanceM),
            ),
            _MetricRow(
              label: l10n.elapsed,
              value: formatDurationMmSs(item.elapsedS),
            ),
            _MetricRow(
              label: l10n.paused,
              value: formatDurationMmSs(item.pausedS),
            ),
            _MetricRow(
              label: l10n.moving,
              value: formatDurationMmSs(item.movingS),
            ),
            _MetricRow(
              label: l10n.capturedArea,
              value: formatAreaM2(item.captureAreaM2),
            ),
            _MetricRow(label: l10n.victims, value: '${item.victimsCount}'),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

String? _formatDateTime(DateTime? dt) {
  if (dt == null) return null;
  return DateFormat('dd.MM.yyyy HH:mm').format(dt);
}
