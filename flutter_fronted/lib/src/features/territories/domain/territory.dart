import 'package:latlong2/latlong.dart';

enum TerritoryFeatureKind { territory, contestedArea }

enum TerritoryStatus { protected, contested, vulnerable }

class TerritoryParticipant {
  const TerritoryParticipant({
    required this.userId,
    required this.displayName,
    required this.territoryColorHex,
  });

  final String userId;
  final String displayName;
  final String territoryColorHex;
}

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
    required this.featureKind,
    required this.territoryId,
    this.contestedAreaId,
    required this.userId,
    required this.displayName,
    required this.areaM2,
    required this.territoryColorHex,
    required this.status,
    this.capturedAt,
    this.protectedUntil,
    this.resolveAt,
    this.currentWinnerUserId,
    this.currentWinnerDisplayName,
    this.currentWinnerTerritoryColorHex,
    this.participants = const [],
    required this.polygons,
    required this.polygonAreasM2,
    required this.avatarUrl,
    required this.stats,
  });

  final TerritoryFeatureKind featureKind;
  final String territoryId;
  final String? contestedAreaId;
  final String userId;

  /// Shown on the map territory label.
  final String displayName;
  final double areaM2;
  final String territoryColorHex;
  final TerritoryStatus status;
  final DateTime? capturedAt;
  final DateTime? protectedUntil;
  final DateTime? resolveAt;
  final String? currentWinnerUserId;
  final String? currentWinnerDisplayName;
  final String? currentWinnerTerritoryColorHex;
  final List<TerritoryParticipant> participants;
  final String? avatarUrl;
  final TerritoryOwnerStats stats;

  /// Each item is a polygon ring (no holes for MVP).
  final List<List<LatLng>> polygons;
  final List<double> polygonAreasM2;
}
