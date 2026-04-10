import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/leaderboard_controller.dart';
import '../domain/leaderboard_models.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
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
    ref.read(leaderboardPagingProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final leaderboardAsync = ref.watch(leaderboardPagingProvider);
    final filter = ref.watch(leaderboardFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Рейтинг')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SegmentedButton<LeaderboardScope>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: LeaderboardScope.city,
                      label: Text('Город'),
                    ),
                    ButtonSegment(
                      value: LeaderboardScope.region,
                      label: Text('Область'),
                    ),
                    ButtonSegment(
                      value: LeaderboardScope.country,
                      label: Text('Страна'),
                    ),
                  ],
                  selected: {filter.scope},
                  onSelectionChanged: (selection) {
                    ref
                        .read(leaderboardFilterProvider.notifier)
                        .setScope(selection.first);
                    ref.read(leaderboardPagingProvider.notifier).refreshList();
                  },
                ),
                const SizedBox(height: 8),
                SegmentedButton<LeaderboardMetric>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: LeaderboardMetric.area,
                      label: Text('Площадь'),
                    ),
                    ButtonSegment(
                      value: LeaderboardMetric.distance,
                      label: Text('Дистанция'),
                    ),
                  ],
                  selected: {filter.metric},
                  onSelectionChanged: (selection) {
                    ref
                        .read(leaderboardFilterProvider.notifier)
                        .setMetric(selection.first);
                    ref.read(leaderboardPagingProvider.notifier).refreshList();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(leaderboardPagingProvider.notifier)
                    .refreshList();
              },
              child: leaderboardAsync.when(
                data: (data) {
                  if (data.entries.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Пока нет данных рейтинга для этого фильтра',
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount:
                        data.entries.length + 1 + (data.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == data.entries.length + 1) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (index == 0) {
                        final rank = data.myRank;
                        final score = data.myScore;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              rank == null || score == null
                                  ? 'Ваш ранг пока не определен'
                                  : 'Ваш ранг: №$rank • ${_formatScore(data.metric, score)}',
                            ),
                          ),
                        );
                      }
                      final entry = data.entries[index - 1];
                      return _LeaderboardRow(entry: entry, metric: data.metric);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(error.toString()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.metric});

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (entry.avatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(entry.avatarUrl!)
              : null,
          child: (entry.avatarUrl?.isNotEmpty ?? false)
              ? null
              : Text(entry.rank.toString()),
        ),
        title: Text('№${entry.rank} ${entry.displayName}'),
        subtitle: Text(
          'Площадь: ${formatAreaM2(entry.ownedAreaM2)} • Дистанция: ${formatMeters(entry.totalDistanceM)}',
        ),
        trailing: Text(
          _formatScore(metric, entry.score),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

String _formatScore(LeaderboardMetric metric, double score) {
  if (metric == LeaderboardMetric.area) {
    return formatAreaM2(score);
  }
  return formatMeters(score);
}
