import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/locations_api.dart';
import '../data/locations_repository.dart';
import '../domain/location_models.dart';
import '../domain/repositories/locations_repository.dart';
import '../domain/usecases/get_countries.dart';
import '../domain/usecases/search_cities.dart';
import '../domain/usecases/search_regions.dart';

final locationsApiProvider = Provider<LocationsApi>((ref) {
  return LocationsApi(ref.watch(dioProvider));
});

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepositoryImpl(ref.watch(locationsApiProvider));
});

final getCountriesUseCaseProvider = Provider<GetCountriesUseCase>((ref) {
  return GetCountriesUseCase(ref.watch(locationsRepositoryProvider));
});

final searchRegionsUseCaseProvider = Provider<SearchRegionsUseCase>((ref) {
  return SearchRegionsUseCase(ref.watch(locationsRepositoryProvider));
});

final searchCitiesUseCaseProvider = Provider<SearchCitiesUseCase>((ref) {
  return SearchCitiesUseCase(ref.watch(locationsRepositoryProvider));
});

final countriesProvider = FutureProvider<List<CountryItem>>((ref) async {
  return ref.watch(getCountriesUseCaseProvider)();
});

final regionsSearchProvider = FutureProvider.family<List<RegionItem>, String>((
  ref,
  query,
) async {
  return ref.watch(searchRegionsUseCaseProvider)(
    countryCode: 'RU',
    query: query,
  );
});

class CitiesSearchParams {
  const CitiesSearchParams({
    required this.regionCode,
    required this.query,
  });

  final String regionCode;
  final String query;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CitiesSearchParams &&
        other.regionCode == regionCode &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(regionCode, query);
}

final citiesSearchProvider =
    FutureProvider.family<List<CityItem>, CitiesSearchParams>((ref, params) async {
      if (params.regionCode.isEmpty) {
        return const [];
      }
      return ref.watch(searchCitiesUseCaseProvider)(
        countryCode: 'RU',
        regionCode: params.regionCode,
        query: params.query,
      );
    });
