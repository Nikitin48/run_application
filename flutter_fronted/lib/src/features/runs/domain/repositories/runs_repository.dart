import '../run_models.dart';

abstract interface class RunsRepository {
  Future<FinishRunResponse> finish(FinishRunRequest request);
}


