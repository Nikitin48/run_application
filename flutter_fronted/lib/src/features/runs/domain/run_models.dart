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
    required this.distanceM,
    required this.elapsedS,
    required this.pausedS,
    required this.movingS,
    required this.captureAreaM2,
    required this.victimsCount,
  });

  final String runId;
  final double distanceM;
  final int elapsedS;
  final int pausedS;
  final int movingS;
  final double captureAreaM2;
  final int victimsCount;

  static FinishRunResponse fromJson(Map<String, Object?> json) {
    return FinishRunResponse(
      runId: json['run_id'] as String,
      distanceM: (json['distance_m'] as num).toDouble(),
      elapsedS: (json['elapsed_s'] as num).toInt(),
      pausedS: (json['paused_s'] as num).toInt(),
      movingS: (json['moving_s'] as num).toInt(),
      captureAreaM2: (json['capture_area_m2'] as num).toDouble(),
      victimsCount: (json['victims_count'] as num).toInt(),
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
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
