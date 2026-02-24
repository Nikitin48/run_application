import '../me_profile.dart';
import '../repositories/profile_repository.dart';

class GetMeProfileUseCase {
  GetMeProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<MeProfile> call() => _repo.getMeProfile();
}
