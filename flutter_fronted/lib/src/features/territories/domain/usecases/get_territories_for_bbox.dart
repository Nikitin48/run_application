import '../repositories/territories_repository.dart';
import '../territory.dart';
import '../value_objects/bbox.dart';

class GetTerritoriesForBboxUseCase {
  GetTerritoriesForBboxUseCase(this._repo);

  final TerritoriesRepository _repo;

  Future<List<Territory>> call(Bbox bbox) {
    return _repo.fetchByBbox(
      minLng: bbox.minLng,
      minLat: bbox.minLat,
      maxLng: bbox.maxLng,
      maxLat: bbox.maxLat,
    );
  }
}


