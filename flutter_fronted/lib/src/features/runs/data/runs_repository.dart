import '../domain/run_models.dart';
import '../domain/repositories/runs_repository.dart';
import 'runs_api.dart';

class RunsRepositoryImpl implements RunsRepository {
  RunsRepositoryImpl(this._api);

  final RunsApi _api;

  @override
  Future<FinishRunResponse> finish(FinishRunRequest request) =>
      _api.finish(request);

  @override
  Future<List<RunHistoryItem>> history({int limit = 50, int offset = 0}) {
    return _api.history(limit: limit, offset: offset);
  }
}
