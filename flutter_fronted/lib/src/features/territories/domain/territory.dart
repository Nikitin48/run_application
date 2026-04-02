import 'package:latlong2/latlong.dart';

class TerritoryOwnerStats {
  const TerritoryOwnerStats({
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

class Territory {
  const Territory({
    required this.userId,
    required this.displayName,
    required this.areaM2,
    required this.territoryColorHex,
    required this.polygons,
    required this.polygonAreasM2,
    required this.avatarUrl,
    required this.stats,
  });

  final String userId;

  /// Shown on the map territory label.
  final String displayName;
  final double areaM2;
  final String territoryColorHex;
  final String? avatarUrl;
  final TerritoryOwnerStats stats;

  /// Each item is a polygon ring (no holes for MVP).
  final List<List<LatLng>> polygons;
  final List<double> polygonAreasM2;
}
