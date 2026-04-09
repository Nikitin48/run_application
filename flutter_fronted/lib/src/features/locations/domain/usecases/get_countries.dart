import '../location_models.dart';
import '../repositories/locations_repository.dart';

class GetCountriesUseCase {
  GetCountriesUseCase(this._repo);

  final LocationsRepository _repo;

  Future<List<CountryItem>> call() => _repo.getCountries();
}
