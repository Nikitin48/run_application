import '../domain/run_models.dart';
import '../domain/repositories/runs_repository.dart';
import 'runs_api.dart';

class RunsRepositoryImpl implements RunsRepository {
  RunsRepositoryImpl(this._api);

  final RunsApi _api;

  Future<FinishRunResponse> finish(FinishRunRequest request) => _api.finish(request);
}


