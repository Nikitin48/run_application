import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../runs/application/run_tracker_controller.dart';
import '../../runs/domain/run_models.dart';
import '../domain/usecases/get_run_history.dart';

final getRunHistoryUseCaseProvider = Provider<GetRunHistoryUseCase>((ref) {
  return GetRunHistoryUseCase(ref.watch(runsRepositoryProvider));
});

class RunHistoryPagingState {
  const RunHistoryPagingState({
    required this.items,
    required this.offset,
    required this.hasMore,
    required this.isLoadingMore,
  });

  static const int pageSize = 5;

  final List<RunHistoryItem> items;
  final int offset;
  final bool hasMore;
  final bool isLoadingMore;

  RunHistoryPagingState copyWith({
    List<RunHistoryItem>? items,
    int? offset,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RunHistoryPagingState(
      items: items ?? this.items,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final runHistoryProvider =
    AsyncNotifierProvider<RunHistoryPagingController, RunHistoryPagingState>(
      RunHistoryPagingController.new,
    );

class RunHistoryPagingController extends AsyncNotifier<RunHistoryPagingState> {
  Future<RunHistoryPagingState> _loadPage({
    required int offset,
    required List<RunHistoryItem> previous,
  }) async {
    final page = await ref.read(getRunHistoryUseCaseProvider)(
      limit: RunHistoryPagingState.pageSize,
      offset: offset,
    );
    final merged = <RunHistoryItem>[...previous, ...page];
    return RunHistoryPagingState(
      items: merged,
      offset: merged.length,
      hasMore: page.length == RunHistoryPagingState.pageSize,
      isLoadingMore: false,
    );
  }

  @override
  Future<RunHistoryPagingState> build() {
    return _loadPage(offset: 0, previous: const []);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _loadPage(
        offset: current.offset,
        previous: current.items,
      );
      state = AsyncData(next);
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _loadPage(offset: 0, previous: const []);
    });
  }
}
