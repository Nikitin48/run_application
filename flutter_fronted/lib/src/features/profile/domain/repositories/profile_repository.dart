import '../me_profile.dart';

abstract class ProfileRepository {
  Future<MeProfile> getMeProfile();
  Future<MeProfile> updateMeProfile({String? displayName, String? avatarUrl});
  Future<String> updateTerritoryColor(String territoryColor);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
