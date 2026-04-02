import 'package:image_picker/image_picker.dart';

import '../domain/me_profile.dart';
import '../domain/repositories/profile_repository.dart';
import 'profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<MeProfile> getMeProfile() async {
    final json = await _api.getMeProfile();
    return _fromJson(json);
  }

  @override
  Future<MeProfile> updateMeProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final json = await _api.updateMeProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    return _fromJson(json);
  }

  @override
  Future<String> updateTerritoryColor(String territoryColor) {
    return _api.updateTerritoryColor(territoryColor);
  }

  @override
  Future<String?> uploadAvatar(XFile file) {
    return _api.uploadAvatar(file);
  }

  @override
  Future<void> deleteAvatar() {
    return _api.deleteAvatar();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  MeProfile _fromJson(Map<String, dynamic> json) {
    final statsJson =
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MeProfile(
      id: (json['id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      territoryColor: (json['territory_color'] as String?) ?? '#3B82F6',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
      stats: MeProfileStats(
        runCount: (statsJson['run_count'] as num?)?.toInt() ?? 0,
        totalDistanceM:
            (statsJson['total_distance_m'] as num?)?.toDouble() ?? 0,
        totalElapsedS: (statsJson['total_elapsed_s'] as num?)?.toInt() ?? 0,
        totalPausedS: (statsJson['total_paused_s'] as num?)?.toInt() ?? 0,
        totalMovingS: (statsJson['total_moving_s'] as num?)?.toInt() ?? 0,
        ownedAreaM2: (statsJson['owned_area_m2'] as num?)?.toDouble() ?? 0,
      ),
    );
  }
}
