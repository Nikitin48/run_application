import '../me_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateMeProfileUseCase {
  UpdateMeProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<MeProfile> call({String? displayName, String? avatarUrl}) {
    return _repo.updateMeProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}
