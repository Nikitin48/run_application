import '../repositories/profile_repository.dart';

class UpdateTerritoryColorUseCase {
  UpdateTerritoryColorUseCase(this._repo);

  final ProfileRepository _repo;

  Future<String> call(String territoryColor) =>
      _repo.updateTerritoryColor(territoryColor);
}
