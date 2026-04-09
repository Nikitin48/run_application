import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/leaderboard_api.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/repositories/leaderboard_repository.dart';
import '../domain/usecases/get_leaderboard.dart';

final leaderboardApiProvider = Provider<LeaderboardApi>((ref) {
  return LeaderboardApi(ref.watch(dioProvider));
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(ref.watch(leaderboardApiProvider));
});

final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>((ref) {
  return GetLeaderboardUseCase(ref.watch(leaderboardRepositoryProvider));
});

class LeaderboardFilterState {
  const LeaderboardFilterState({
    required this.scope,
    required this.metric,
  });

  final LeaderboardScope scope;
  final LeaderboardMetric metric;

  LeaderboardFilterState copyWith({
    LeaderboardScope? scope,
    LeaderboardMetric? metric,
  }) {
    return LeaderboardFilterState(
      scope: scope ?? this.scope,
      metric: metric ?? this.metric,
    );
  }
}

final leaderboardFilterProvider =
    NotifierProvider<LeaderboardFilterController, LeaderboardFilterState>(
      LeaderboardFilterController.new,
    );

class LeaderboardFilterController extends Notifier<LeaderboardFilterState> {
  @override
  LeaderboardFilterState build() {
    return const LeaderboardFilterState(
      scope: LeaderboardScope.country,
      metric: LeaderboardMetric.area,
    );
  }

  void setScope(LeaderboardScope scope) {
    state = state.copyWith(scope: scope);
  }

  void setMetric(LeaderboardMetric metric) {
    state = state.copyWith(metric: metric);
  }
}

class LeaderboardPagingState {
  const LeaderboardPagingState({
    required this.scope,
    required this.metric,
    required this.entries,
    required this.myRank,
    required this.myScore,
    required this.offset,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final LeaderboardScope scope;
  final LeaderboardMetric metric;
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final double? myScore;
  final int offset;
  final bool hasMore;
  final bool isLoadingMore;

  static const pageSize = 20;

  LeaderboardPagingState copyWith({
    LeaderboardScope? scope,
    LeaderboardMetric? metric,
    List<LeaderboardEntry>? entries,
    int? myRank,
    double? myScore,
    int? offset,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return LeaderboardPagingState(
      scope: scope ?? this.scope,
      metric: metric ?? this.metric,
      entries: entries ?? this.entries,
      myRank: myRank ?? this.myRank,
      myScore: myScore ?? this.myScore,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final leaderboardPagingProvider =
    AsyncNotifierProvider<LeaderboardPagingController, LeaderboardPagingState>(
      LeaderboardPagingController.new,
    );

class LeaderboardPagingController extends AsyncNotifier<LeaderboardPagingState> {
  Future<LeaderboardPagingState> _loadPage({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    required int offset,
    required List<LeaderboardEntry> previous,
  }) async {
    final page = await ref.read(getLeaderboardUseCaseProvider)(
      scope: scope,
      metric: metric,
      limit: LeaderboardPagingState.pageSize,
      offset: offset,
    );
    final merged = <LeaderboardEntry>[
      ...previous,
      ...page.entries,
    ];
    return LeaderboardPagingState(
      scope: scope,
      metric: metric,
      entries: merged,
      myRank: page.myRank,
      myScore: page.myScore,
      offset: merged.length,
      hasMore: page.entries.length == LeaderboardPagingState.pageSize,
      isLoadingMore: false,
    );
  }

  @override
  Future<LeaderboardPagingState> build() async {
    final filter = ref.watch(leaderboardFilterProvider);
    return _loadPage(
      scope: filter.scope,
      metric: filter.metric,
      offset: 0,
      previous: const [],
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _loadPage(
        scope: current.scope,
        metric: current.metric,
        offset: current.offset,
        previous: current.entries,
      );
      state = AsyncData(next);
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filter = ref.read(leaderboardFilterProvider);
      return _loadPage(
        scope: filter.scope,
        metric: filter.metric,
        offset: 0,
        previous: const [],
      );
    });
  }
}
