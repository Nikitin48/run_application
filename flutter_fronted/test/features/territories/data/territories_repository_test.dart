import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_application/src/features/territories/data/territories_api.dart';
import 'package:run_application/src/features/territories/data/territories_repository.dart';
import 'package:run_application/src/features/territories/domain/territory.dart';

class _FakeTerritoriesApi extends TerritoriesApi {
  _FakeTerritoriesApi(this.payload) : super(Dio());

  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> getTerritories({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
  }) async {
    return payload;
  }
}

void main() {
  group('TerritoriesRepositoryImpl', () {
    test('parses contested area metadata from GeoJSON features', () async {
      final repo = TerritoriesRepositoryImpl(
        _FakeTerritoriesApi({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [37.0, 55.0],
                    [37.1, 55.0],
                    [37.1, 55.1],
                    [37.0, 55.0],
                  ],
                ],
              },
              'properties': {
                'feature_kind': 'contested_area',
                'territory_id': 'territory-1',
                'contested_area_id': 'contest-1',
                'user_id': 'owner-1',
                'display_name': 'Owner',
                'territory_color': '#3B82F6',
                'area_m2': 250.0,
                'status': 'contested',
                'resolve_at': '2026-05-28T18:00:00Z',
                'current_winner_user_id': 'runner-1',
                'current_winner_display_name': 'Runner',
                'current_winner_territory_color': '#22C55E',
                'participants': [
                  {
                    'user_id': 'owner-1',
                    'display_name': 'Owner',
                    'territory_color': '#3B82F6',
                  },
                  {
                    'user_id': 'runner-1',
                    'display_name': 'Runner',
                    'territory_color': '#22C55E',
                  },
                ],
                'polygon_areas_m2': [250.0],
              },
            },
          ],
        }),
      );

      final territories = await repo.fetchByBbox(
        minLng: 37,
        minLat: 55,
        maxLng: 38,
        maxLat: 56,
      );

      expect(territories, hasLength(1));
      final contested = territories.single;
      expect(contested.featureKind, TerritoryFeatureKind.contestedArea);
      expect(contested.status, TerritoryStatus.contested);
      expect(contested.contestedAreaId, 'contest-1');
      expect(contested.currentWinnerDisplayName, 'Runner');
      expect(contested.participants.map((p) => p.userId), [
        'owner-1',
        'runner-1',
      ]);
      expect(contested.polygons.single.first.latitude, 55.0);
      expect(contested.polygons.single.first.longitude, 37.0);
    });

    test('parses total owned area separately from fragment area', () async {
      final repo = TerritoriesRepositoryImpl(
        _FakeTerritoriesApi({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [37.0, 55.0],
                    [37.1, 55.0],
                    [37.1, 55.1],
                    [37.0, 55.0],
                  ],
                ],
              },
              'properties': {
                'feature_kind': 'territory',
                'territory_id': 'fragment-1',
                'user_id': 'owner-1',
                'display_name': 'Owner',
                'territory_color': '#3B82F6',
                'area_m2': 400.0,
                'status': 'protected',
                'stats': {
                  'run_count': 3,
                  'total_distance_m': 1200,
                  'total_elapsed_s': 600,
                  'total_paused_s': 30,
                  'total_moving_s': 570,
                  'owned_area_m2': 1500.0,
                },
                'polygon_areas_m2': [400.0],
              },
            },
          ],
        }),
      );

      final territories = await repo.fetchByBbox(
        minLng: 37,
        minLat: 55,
        maxLng: 38,
        maxLat: 56,
      );

      final fragment = territories.single;
      expect(fragment.areaM2, 400.0);
      expect(fragment.stats.ownedAreaM2, 1500.0);
    });
  });
}
