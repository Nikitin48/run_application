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
      final userId = (props['user_id'] ?? '') as String;
      final displayName = (props['display_name'] as String?) ?? '';
      final areaM2 = (props['area_m2'] as num?)?.toDouble() ?? 0.0;
      final territoryColorHex =
          (props['territory_color'] as String?) ?? '#3B82F6';
      final avatarUrl = props['avatar_url'] as String?;
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
          userId: userId,
          displayName: displayName,
          areaM2: areaM2,
          territoryColorHex: territoryColorHex,
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
            ownedAreaM2:
                (statsJson['owned_area_m2'] as num?)?.toDouble() ?? areaM2,
          ),
        ),
      );
    }

    return out;
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
