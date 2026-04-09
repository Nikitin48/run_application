import '../location_models.dart';
import '../repositories/locations_repository.dart';

class SearchRegionsUseCase {
  SearchRegionsUseCase(this._repo);

  final LocationsRepository _repo;

  Future<List<RegionItem>> call({
    required String countryCode,
    required String query,
    int limit = 20,
    int offset = 0,
  }) {
    return _repo.searchRegions(
      countryCode: countryCode,
      query: query,
      limit: limit,
      offset: offset,
    );
  }
}
