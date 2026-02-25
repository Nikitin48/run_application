import '../../../runs/domain/repositories/runs_repository.dart';
import '../../../runs/domain/run_models.dart';

class GetRunHistoryUseCase {
  GetRunHistoryUseCase(this._repo);

  final RunsRepository _repo;

  Future<List<RunHistoryItem>> call({int limit = 50, int offset = 0}) {
    return _repo.history(limit: limit, offset: offset);
  }
}
