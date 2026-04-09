import '../location_models.dart';

abstract class LocationsRepository {
  Future<List<CountryItem>> getCountries();
  Future<List<RegionItem>> searchRegions({
    required String countryCode,
    required String query,
    int limit,
    int offset,
  });
  Future<List<CityItem>> searchCities({
    required String countryCode,
    required String regionCode,
    required String query,
    int limit,
    int offset,
  });
}
