import '../territory.dart';

abstract interface class TerritoriesRepository {
  Future<List<Territory>> fetchByBbox({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
  });
}
