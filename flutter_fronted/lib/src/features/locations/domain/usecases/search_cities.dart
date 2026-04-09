import '../location_models.dart';
import '../repositories/locations_repository.dart';

class SearchCitiesUseCase {
  SearchCitiesUseCase(this._repo);

  final LocationsRepository _repo;

  Future<List<CityItem>> call({
    required String countryCode,
    required String regionCode,
    required String query,
    int limit = 20,
    int offset = 0,
  }) {
    return _repo.searchCities(
      countryCode: countryCode,
      regionCode: regionCode,
      query: query,
      limit: limit,
      offset: offset,
    );
  }
}
