import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../runs/application/run_tracker_controller.dart';
import '../../runs/domain/run_models.dart';
import '../domain/usecases/get_run_history.dart';

final getRunHistoryUseCaseProvider = Provider<GetRunHistoryUseCase>((ref) {
  return GetRunHistoryUseCase(ref.watch(runsRepositoryProvider));
});

final runHistoryProvider = FutureProvider<List<RunHistoryItem>>((ref) async {
  return ref.watch(getRunHistoryUseCaseProvider)(limit: 100, offset: 0);
});
