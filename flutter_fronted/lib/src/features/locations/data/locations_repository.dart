import '../domain/location_models.dart';
import '../domain/repositories/locations_repository.dart';
import 'locations_api.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  LocationsRepositoryImpl(this._api);

  final LocationsApi _api;

  @override
  Future<List<CountryItem>> getCountries() async {
    final rows = await _api.getCountries();
    return rows
        .map(
          (row) => CountryItem(
            code: (row['code'] as String?) ?? '',
            name: (row['name'] as String?) ?? '',
          ),
        )
        .where((item) => item.code.isNotEmpty && item.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<RegionItem>> searchRegions({
    required String countryCode,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _api.searchRegions(
      countryCode: countryCode,
      query: query,
      limit: limit,
      offset: offset,
    );
    return rows
        .map(
          (row) => RegionItem(
            code: (row['code'] as String?) ?? '',
            name: (row['name'] as String?) ?? '',
            countryCode: (row['country_code'] as String?) ?? '',
          ),
        )
        .where((item) => item.code.isNotEmpty && item.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<CityItem>> searchCities({
    required String countryCode,
    required String regionCode,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _api.searchCities(
      countryCode: countryCode,
      regionCode: regionCode,
      query: query,
      limit: limit,
      offset: offset,
    );
    return rows
        .map(
          (row) => CityItem(
            code: (row['code'] as String?) ?? '',
            name: (row['name'] as String?) ?? '',
            countryCode: (row['country_code'] as String?) ?? '',
            regionCode: (row['region_code'] as String?) ?? '',
          ),
        )
        .where((item) => item.code.isNotEmpty && item.name.isNotEmpty)
        .toList(growable: false);
  }
}
