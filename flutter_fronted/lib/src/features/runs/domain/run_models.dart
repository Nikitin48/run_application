class RunPoint {
  const RunPoint({
    required this.lat,
    required this.lng,
    required this.ts,
    this.accuracyM,
    this.speedMps,
    this.altitudeM,
  });

  final double lat;
  final double lng;
  final DateTime ts;
  final double? accuracyM;
  final double? speedMps;
  final double? altitudeM;

  Map<String, Object?> toJson() => {
    'lat': lat,
    'lng': lng,
    'ts': ts.toUtc().toIso8601String(),
    if (accuracyM != null) 'accuracy_m': accuracyM,
    if (speedMps != null) 'speed_mps': speedMps,
    if (altitudeM != null) 'altitude_m': altitudeM,
  };
}

enum PauseReason { manual, gpsLost, internetLost }

class RunPause {
  const RunPause({required this.startedAt, required this.reason, this.endedAt});

  final DateTime startedAt;
  final DateTime? endedAt;
  final PauseReason reason;

  bool get isOpen => endedAt == null;

  RunPause close(DateTime endedAt) =>
      RunPause(startedAt: startedAt, endedAt: endedAt, reason: reason);

  Map<String, Object?> toJson() => {
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt?.toUtc().toIso8601String(),
    'reason': switch (reason) {
      PauseReason.manual => 'manual',
      PauseReason.gpsLost => 'gps_lost',
      PauseReason.internetLost => 'internet_lost',
    },
  };
}

class FinishRunRequest {
  const FinishRunRequest({
    required this.startedAt,
    required this.endedAt,
    required this.points,
    required this.pauses,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final List<RunPoint> points;
  final List<RunPause> pauses;

  Map<String, Object?> toJson() => {
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt.toUtc().toIso8601String(),
    'points': points.map((p) => p.toJson()).toList(),
    'pauses': pauses.map((p) => p.toJson()).toList(),
  };
}

class FinishRunResponse {
  const FinishRunResponse({
    required this.runId,
    required this.startedAt,
    required this.endedAt,
    required this.distanceM,
    required this.elapsedS,
    required this.pausedS,
    required this.movingS,
    required this.captureAreaM2,
    required this.victimsCount,
    required this.capturePolygons,
    required this.trackPoints,
    required this.newAchievements,
    required this.levelUp,
    required this.profileXp,
    required this.profileLevel,
  });

  final String runId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int elapsedS;
  final int pausedS;
  final int movingS;
  final double captureAreaM2;
  final int victimsCount;
  final List<List<RunGeoPoint>> capturePolygons;
  final List<RunGeoPoint> trackPoints;
  final List<UnlockedAchievement> newAchievements;
  final LevelUpInfo? levelUp;
  final int profileXp;
  final int profileLevel;

  static FinishRunResponse fromJson(Map<String, Object?> json) {
    final newAchievementsRaw = (json['new_achievements'] as List?) ?? const [];
    final startedAtRaw = json['started_at'] as String?;
    final endedAtRaw = json['ended_at'] as String?;
    return FinishRunResponse(
      runId: json['run_id'] as String,
      startedAt: startedAtRaw == null
          ? null
          : DateTime.tryParse(startedAtRaw)?.toLocal(),
      endedAt: endedAtRaw == null ? null : DateTime.tryParse(endedAtRaw)?.toLocal(),
      distanceM: (json['distance_m'] as num).toDouble(),
      elapsedS: (json['elapsed_s'] as num).toInt(),
      pausedS: (json['paused_s'] as num).toInt(),
      movingS: (json['moving_s'] as num).toInt(),
      captureAreaM2: (json['capture_area_m2'] as num).toDouble(),
      victimsCount: (json['victims_count'] as num).toInt(),
      capturePolygons: _parseCapturePolygonsGeoJson(json['capture_geojson']),
      trackPoints: _parseTrackPointsGeoJson(json['track_geojson']),
      newAchievements: newAchievementsRaw
          .whereType<Map<String, Object?>>()
          .map(UnlockedAchievement.fromJson)
          .toList(growable: false),
      levelUp: (json['level_up'] as Map<String, Object?>?) == null
          ? null
          : LevelUpInfo.fromJson(json['level_up'] as Map<String, Object?>),
      profileXp: (json['profile_xp'] as num?)?.toInt() ?? 0,
      profileLevel: (json['profile_level'] as num?)?.toInt() ?? 1,
    );
  }
}

class UnlockedAchievement {
  const UnlockedAchievement({
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.xp,
    required this.unlockedAt,
  });

  final String code;
  final String title;
  final String description;
  final String category;
  final String iconKey;
  final int xp;
  final DateTime unlockedAt;

  static UnlockedAchievement fromJson(Map<String, Object?> json) {
    return UnlockedAchievement(
      code: (json['code'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      iconKey: (json['icon_key'] as String?) ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      unlockedAt:
          DateTime.tryParse((json['unlocked_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class LevelUpInfo {
  const LevelUpInfo({required this.oldLevel, required this.newLevel});

  final int oldLevel;
  final int newLevel;

  static LevelUpInfo fromJson(Map<String, Object?> json) {
    return LevelUpInfo(
      oldLevel: (json['old_level'] as num?)?.toInt() ?? 1,
      newLevel: (json['new_level'] as num?)?.toInt() ?? 1,
    );
  }
}

class RunHistoryItem {
  const RunHistoryItem({
    required this.runId,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.distanceM,
    required this.elapsedS,
    required this.pausedS,
    required this.movingS,
    required this.captureAreaM2,
    required this.victimsCount,
    required this.capturePolygons,
    required this.trackPoints,
    required this.createdAt,
  });

  final String runId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int elapsedS;
  final int pausedS;
  final int movingS;
  final double captureAreaM2;
  final int victimsCount;
  final List<List<RunGeoPoint>> capturePolygons;
  final List<RunGeoPoint> trackPoints;
  final DateTime createdAt;

  static RunHistoryItem fromJson(Map<String, Object?> json) {
    final startedAtRaw = json['started_at'] as String?;
    final endedAtRaw = json['ended_at'] as String?;
    return RunHistoryItem(
      runId: json['run_id'] as String,
      status: (json['status'] as String?) ?? 'unknown',
      startedAt: startedAtRaw == null
          ? null
          : DateTime.tryParse(startedAtRaw)?.toLocal(),
      endedAt: endedAtRaw == null
          ? null
          : DateTime.tryParse(endedAtRaw)?.toLocal(),
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
      elapsedS: (json['elapsed_s'] as num?)?.toInt() ?? 0,
      pausedS: (json['paused_s'] as num?)?.toInt() ?? 0,
      movingS: (json['moving_s'] as num?)?.toInt() ?? 0,
      captureAreaM2: (json['capture_area_m2'] as num?)?.toDouble() ?? 0,
      victimsCount: (json['victims_count'] as num?)?.toInt() ?? 0,
      capturePolygons: _parseCapturePolygons(json['capture_geojson']),
      trackPoints: _parseTrackPoints(json['track_geojson']),
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  static List<List<RunGeoPoint>> _parseCapturePolygons(Object? rawGeoJson) {
    return _parseCapturePolygonsGeoJson(rawGeoJson);
  }

  static List<RunGeoPoint> _parseTrackPoints(Object? rawGeoJson) {
    return _parseTrackPointsGeoJson(rawGeoJson);
  }
}

class RunGeoPoint {
  const RunGeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

List<List<RunGeoPoint>> _parseCapturePolygonsGeoJson(Object? rawGeoJson) {
  if (rawGeoJson is! Map) return const <List<RunGeoPoint>>[];
  final geoJson = rawGeoJson.cast<Object?, Object?>();
  final type = (geoJson['type'] as String?)?.toLowerCase();
  final coordinates = geoJson['coordinates'];
  if (coordinates is! List) return const <List<RunGeoPoint>>[];

  if (type == 'polygon') {
    if (coordinates.isEmpty) return const <List<RunGeoPoint>>[];
    final ring = _parseRingGeoJson(coordinates.first);
    return ring.isEmpty ? const <List<RunGeoPoint>>[] : <List<RunGeoPoint>>[ring];
  }

  if (type == 'multipolygon') {
    final rings = <List<RunGeoPoint>>[];
    for (final polygonRaw in coordinates) {
      if (polygonRaw is! List || polygonRaw.isEmpty) continue;
      final ring = _parseRingGeoJson(polygonRaw.first);
      if (ring.isNotEmpty) rings.add(ring);
    }
    return List.unmodifiable(rings);
  }

  return const <List<RunGeoPoint>>[];
}

List<RunGeoPoint> _parseTrackPointsGeoJson(Object? rawGeoJson) {
  if (rawGeoJson is! Map) return const <RunGeoPoint>[];
  final geoJson = rawGeoJson.cast<Object?, Object?>();
  final type = (geoJson['type'] as String?)?.toLowerCase();
  if (type != 'linestring') return const <RunGeoPoint>[];
  final coordinates = geoJson['coordinates'];
  if (coordinates is! List) return const <RunGeoPoint>[];
  final points = <RunGeoPoint>[];
  for (final pointRaw in coordinates) {
    if (pointRaw is! List || pointRaw.length < 2) continue;
    final lng = _toDoubleGeoJson(pointRaw[0]);
    final lat = _toDoubleGeoJson(pointRaw[1]);
    if (lng == null || lat == null) continue;
    points.add(RunGeoPoint(lat: lat, lng: lng));
  }
  if (points.length < 2) return const <RunGeoPoint>[];
  return List.unmodifiable(points);
}

List<RunGeoPoint> _parseRingGeoJson(Object? rawRing) {
  if (rawRing is! List) return const <RunGeoPoint>[];
  final points = <RunGeoPoint>[];
  for (final pointRaw in rawRing) {
    if (pointRaw is! List || pointRaw.length < 2) continue;
    final lng = _toDoubleGeoJson(pointRaw[0]);
    final lat = _toDoubleGeoJson(pointRaw[1]);
    if (lng == null || lat == null) continue;
    points.add(RunGeoPoint(lat: lat, lng: lng));
  }
  if (points.length < 3) return const <RunGeoPoint>[];
  return List.unmodifiable(points);
}

double? _toDoubleGeoJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
