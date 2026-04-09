class MeProfileStats {
  const MeProfileStats({
    required this.runCount,
    required this.totalDistanceM,
    required this.totalElapsedS,
    required this.totalPausedS,
    required this.totalMovingS,
    required this.ownedAreaM2,
  });

  final int runCount;
  final double totalDistanceM;
  final int totalElapsedS;
  final int totalPausedS;
  final int totalMovingS;
  final double ownedAreaM2;
}

class MeProfile {
  const MeProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.email,
    required this.territoryColor,
    required this.countryCode,
    required this.countryName,
    required this.regionCode,
    required this.regionName,
    required this.cityCode,
    required this.cityName,
    required this.createdAt,
    required this.stats,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final String territoryColor;
  final String countryCode;
  final String countryName;
  final String? regionCode;
  final String? regionName;
  final String? cityCode;
  final String? cityName;
  final DateTime createdAt;
  final MeProfileStats stats;
}
