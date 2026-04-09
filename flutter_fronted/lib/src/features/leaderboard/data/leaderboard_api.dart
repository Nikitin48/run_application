import 'package:dio/dio.dart';

import '../domain/leaderboard_models.dart';

class LeaderboardApi {
  LeaderboardApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardMetric metric,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/leaderboard',
      queryParameters: {
        'scope': scope.name,
        'metric': metric.name,
        'limit': limit,
        'offset': offset,
      },
    );
    return res.data ?? const {};
  }
}
