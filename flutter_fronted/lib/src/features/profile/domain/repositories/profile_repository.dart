import 'package:image_picker/image_picker.dart';

import '../me_profile.dart';

abstract class ProfileRepository {
  Future<MeProfile> getMeProfile();
  Future<MeProfile> updateMeProfile({
    String? displayName,
    String? avatarUrl,
    String? countryCode,
    String? regionCode,
    String? cityCode,
    bool clearRegion = false,
    bool clearCity = false,
  });
  Future<String> updateTerritoryColor(String territoryColor);
  Future<String?> uploadAvatar(XFile file);
  Future<void> deleteAvatar();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
