import '../repositories/runs_repository.dart';
import '../run_models.dart';

class FinishRunUseCase {
  FinishRunUseCase(this._repo);

  final RunsRepository _repo;

  Future<FinishRunResponse> call(FinishRunRequest request) =>
      _repo.finish(request);
}
