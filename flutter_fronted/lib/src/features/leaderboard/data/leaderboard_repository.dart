import '../domain/leaderboard_models.dart';
import '../domain/repositories/leaderboard_repository.dart';
import 'leaderboard_api.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._api);

  final LeaderboardApi _api;

  @override
  Future<LeaderboardResponse> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    int limit = 20,
    int offset = 0,
  }) async {
    final json = await _api.getLeaderboard(
      scope: scope,
      metric: metric,
      limit: limit,
      offset: offset,
    );
    final entriesRaw = (json['entries'] as List?) ?? const [];
    final entries = entriesRaw
        .whereType<Map>()
        .map((raw) => raw.cast<String, dynamic>())
        .map(
          (row) => LeaderboardEntry(
            rank: (row['rank'] as num?)?.toInt() ?? 0,
            userId: (row['user_id'] as String?) ?? '',
            displayName: (row['display_name'] as String?) ?? '',
            avatarUrl: row['avatar_url'] as String?,
            countryCode: (row['country_code'] as String?) ?? 'RU',
            regionCode: row['region_code'] as String?,
            cityCode: row['city_code'] as String?,
            totalDistanceM: (row['total_distance_m'] as num?)?.toDouble() ?? 0,
            ownedAreaM2: (row['owned_area_m2'] as num?)?.toDouble() ?? 0,
            score: (row['score'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(growable: false);
    return LeaderboardResponse(
      scope: scope,
      metric: metric,
      entries: entries,
      myRank: (json['my_rank'] as num?)?.toInt(),
      myScore: (json['my_score'] as num?)?.toDouble(),
    );
  }
}
