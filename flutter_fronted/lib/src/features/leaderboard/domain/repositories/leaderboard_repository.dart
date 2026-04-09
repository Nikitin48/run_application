import '../leaderboard_models.dart';

abstract class LeaderboardRepository {
  Future<LeaderboardResponse> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    int limit,
    int offset,
  });
}
