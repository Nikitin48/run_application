import 'package:latlong2/latlong.dart';

import '../domain/territory.dart';
import '../domain/repositories/territories_repository.dart';
import 'territories_api.dart';

class TerritoriesRepositoryImpl implements TerritoriesRepository {
  TerritoriesRepositoryImpl(this._api);

  final TerritoriesApi _api;

  @override
  Future<List<Territory>> fetchByBbox({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
  }) async {
    final json = await _api.getTerritories(
      minLng: minLng,
      minLat: minLat,
      maxLng: maxLng,
      maxLat: maxLat,
    );

    final features = (json['features'] as List<dynamic>? ?? const []);
    final out = <Territory>[];

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final props =
          (f['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
      final featureKind = _parseFeatureKind(props['feature_kind'] as String?);
      final territoryId = (props['territory_id'] as String?) ?? '';
      final contestedAreaId = props['contested_area_id'] as String?;
      final userId = (props['user_id'] ?? '') as String;
      final displayName = (props['display_name'] as String?) ?? '';
      final areaM2 = (props['area_m2'] as num?)?.toDouble() ?? 0.0;
      final territoryColorHex =
          (props['territory_color'] as String?) ?? '#3B82F6';
      final avatarUrl = props['avatar_url'] as String?;
      final status = _parseStatus(props['status'] as String?);
      final participantsRaw = props['participants'] as List? ?? const [];
      final participants = participantsRaw
          .whereType<Map>()
          .map((p) {
            final json = p.cast<String, dynamic>();
            return TerritoryParticipant(
              userId: (json['user_id'] as String?) ?? '',
              displayName: (json['display_name'] as String?) ?? '',
              territoryColorHex:
                  (json['territory_color'] as String?) ?? '#3B82F6',
            );
          })
          .toList(growable: false);
      final statsJson =
          (props['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
      final polygonAreasRaw = (props['polygon_areas_m2'] as List?) ?? const [];
      final polygonAreasM2 = polygonAreasRaw
          .map((v) => (v as num).toDouble())
          .toList(growable: false);

      final geometry = (f['geometry'] as Map?)?.cast<String, dynamic>();
      if (geometry == null) continue;

      final type = geometry['type'];
      final coords = geometry['coordinates'];

      final polygons = <List<LatLng>>[];

      if (type == 'Polygon') {
        // coordinates: [ [ [lng,lat], ... ] , ...holes ]
        final rings = (coords as List).cast<dynamic>();
        if (rings.isNotEmpty) {
          polygons.add(_ringToLatLngs(rings.first as List));
        }
      } else if (type == 'MultiPolygon') {
        // coordinates: [ polygon1, polygon2, ... ]
        // each polygon: [ outerRing, ...holes ]
        for (final poly in (coords as List).cast<dynamic>()) {
          final rings = (poly as List).cast<dynamic>();
          if (rings.isNotEmpty) {
            polygons.add(_ringToLatLngs(rings.first as List));
          }
        }
      } else {
        continue;
      }

      out.add(
        Territory(
          featureKind: featureKind,
          territoryId: territoryId,
          contestedAreaId: contestedAreaId,
          userId: userId,
          displayName: displayName,
          areaM2: areaM2,
          territoryColorHex: territoryColorHex,
          status: status,
          capturedAt: _parseDate(props['captured_at'] as String?),
          protectedUntil: _parseDate(props['protected_until'] as String?),
          resolveAt: _parseDate(props['resolve_at'] as String?),
          currentWinnerUserId: props['current_winner_user_id'] as String?,
          currentWinnerDisplayName:
              props['current_winner_display_name'] as String?,
          currentWinnerTerritoryColorHex:
              props['current_winner_territory_color'] as String?,
          participants: participants,
          polygons: polygons,
          polygonAreasM2: polygonAreasM2,
          avatarUrl: avatarUrl,
          stats: TerritoryOwnerStats(
            runCount: (statsJson['run_count'] as num?)?.toInt() ?? 0,
            totalDistanceM:
                (statsJson['total_distance_m'] as num?)?.toDouble() ?? 0,
            totalElapsedS: (statsJson['total_elapsed_s'] as num?)?.toInt() ?? 0,
            totalPausedS: (statsJson['total_paused_s'] as num?)?.toInt() ?? 0,
            totalMovingS: (statsJson['total_moving_s'] as num?)?.toInt() ?? 0,
            ownedAreaM2: (statsJson['owned_area_m2'] as num?)?.toDouble() ?? 0,
          ),
        ),
      );
    }

    return out;
  }

  TerritoryFeatureKind _parseFeatureKind(String? raw) {
    return raw == 'contested_area'
        ? TerritoryFeatureKind.contestedArea
        : TerritoryFeatureKind.territory;
  }

  TerritoryStatus _parseStatus(String? raw) {
    return switch (raw) {
      'contested' => TerritoryStatus.contested,
      'vulnerable' => TerritoryStatus.vulnerable,
      _ => TerritoryStatus.protected,
    };
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  List<LatLng> _ringToLatLngs(List ring) {
    final pts = <LatLng>[];
    for (final c in ring) {
      if (c is! List || c.length < 2) continue;
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      pts.add(LatLng(lat, lng));
    }
    return pts;
  }
}
