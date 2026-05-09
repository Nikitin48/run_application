import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../app/home_shell_page.dart'
    show kShellBottomBarHeight, shellBottomSystemInset;
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../profile/application/profile_controller.dart';
import '../../runs/domain/run_models.dart';
import '../../runs/presentation/widgets/run_stats_card.dart';
import '../application/run_history_provider.dart';

class HistoriesPage extends ConsumerStatefulWidget {
  const HistoriesPage({super.key});

  @override
  ConsumerState<HistoriesPage> createState() => _HistoriesPageState();
}

class _HistoriesPageState extends ConsumerState<HistoriesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 220) return;
    ref.read(runHistoryProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(runHistoryProvider);
    final meProfileAsync = ref.watch(meProfileProvider);
    final previewAccent = meProfileAsync.maybeWhen(
      data: (profile) => colorFromHexOrDefault(profile.territoryColor),
      orElse: () => Theme.of(context).colorScheme.primary,
    );
    final bottomClearance =
        kShellBottomBarHeight + shellBottomSystemInset(context) + 24;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historiesTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(runHistoryProvider.notifier).refreshList();
        },
        child: historyAsync.when(
          data: (data) {
            if (data.items.isEmpty) {
              return ListView(
                controller: _scrollController,
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
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: data.items.length + 1 + (data.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == data.items.length) {
                  return SizedBox(height: bottomClearance);
                }
                if (index == data.items.length + 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _RunHistoryCard(
                  item: data.items[index],
                  previewAccent: previewAccent,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            final message = toUserFriendlyError(
              e,
              fallbackMessage:
                  'Не удалось загрузить историю пробежек. Попробуйте еще раз.',
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(message),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RunHistoryCard extends StatelessWidget {
  const _RunHistoryCard({required this.item, required this.previewAccent});

  final RunHistoryItem item;
  final Color previewAccent;

  @override
  Widget build(BuildContext context) {
    return RunStatsCard(
      startedAt: item.startedAt,
      endedAt: item.endedAt,
      capturePolygons: item.capturePolygons,
      trackPoints: item.trackPoints,
      previewAccent: previewAccent,
      distanceM: item.distanceM,
      elapsedS: item.elapsedS,
      pausedS: item.pausedS,
      movingS: item.movingS,
      captureAreaM2: item.captureAreaM2,
      victimsCount: item.victimsCount,
    );
  }
}
