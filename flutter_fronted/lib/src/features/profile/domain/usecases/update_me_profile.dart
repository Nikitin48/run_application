import '../me_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateMeProfileUseCase {
  UpdateMeProfileUseCase(this._repo);

  final ProfileRepository _repo;

  Future<MeProfile> call({
    String? displayName,
    String? avatarUrl,
    String? countryCode,
    String? regionCode,
    String? cityCode,
    bool clearRegion = false,
    bool clearCity = false,
  }) {
    return _repo.updateMeProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      regionCode: regionCode,
      cityCode: cityCode,
      clearRegion: clearRegion,
      clearCity: clearCity,
    );
  }
}
