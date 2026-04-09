import '../leaderboard_models.dart';
import '../repositories/leaderboard_repository.dart';

class GetLeaderboardUseCase {
  GetLeaderboardUseCase(this._repo);

  final LeaderboardRepository _repo;

  Future<LeaderboardResponse> call({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    int limit = 20,
    int offset = 0,
  }) {
    return _repo.getLeaderboard(
      scope: scope,
      metric: metric,
      limit: limit,
      offset: offset,
    );
  }
}
