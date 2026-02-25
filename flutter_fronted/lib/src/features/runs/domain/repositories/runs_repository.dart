import '../run_models.dart';

abstract interface class RunsRepository {
  Future<FinishRunResponse> finish(FinishRunRequest request);
  Future<List<RunHistoryItem>> history({int limit, int offset});
}
