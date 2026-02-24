import 'package:latlong2/latlong.dart';

import '../domain/territory.dart';
import '../domain/repositories/territories_repository.dart';
import 'territories_api.dart';

class TerritoriesRepositoryImpl implements TerritoriesRepository {
  TerritoriesRepositoryImpl(this._api);

  final TerritoriesApi _api;

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
      final areaM2 = (props['area_m2'] as num?)?.toDouble() ?? 0.0;
      final territoryColorHex =
          (props['territory_color'] as String?) ?? '#3B82F6';

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
          areaM2: areaM2,
          territoryColorHex: territoryColorHex,
          polygons: polygons,
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
