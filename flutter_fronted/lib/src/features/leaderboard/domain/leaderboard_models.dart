enum LeaderboardScope { city, region, country }

enum LeaderboardMetric { area, distance }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.countryCode,
    required this.regionCode,
    required this.cityCode,
    required this.totalDistanceM,
    required this.ownedAreaM2,
    required this.score,
  });

  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String countryCode;
  final String? regionCode;
  final String? cityCode;
  final double totalDistanceM;
  final double ownedAreaM2;
  final double score;
}

class LeaderboardResponse {
  const LeaderboardResponse({
    required this.scope,
    required this.metric,
    required this.entries,
    required this.myRank,
    required this.myScore,
  });

  final LeaderboardScope scope;
  final LeaderboardMetric metric;
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final double? myScore;
}
