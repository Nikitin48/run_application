import 'package:image_picker/image_picker.dart';

import '../domain/achievement_models.dart';
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
  Future<AchievementsOverview> getMyAchievements() async {
    final json = await _api.getMyAchievements();
    final itemsRaw = (json['items'] as List?) ?? const [];
    return AchievementsOverview(
      profileXp: (json['profile_xp'] as num?)?.toInt() ?? 0,
      profileLevel: (json['profile_level'] as num?)?.toInt() ?? 1,
      items: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(_achievementFromJson)
          .toList(growable: false),
    );
  }

  @override
  Future<MeProfile> updateMeProfile({
    String? displayName,
    String? avatarUrl,
    String? countryCode,
    String? regionCode,
    String? cityCode,
    bool clearRegion = false,
    bool clearCity = false,
  }) async {
    final json = await _api.updateMeProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      regionCode: regionCode,
      cityCode: cityCode,
      clearRegion: clearRegion,
      clearCity: clearCity,
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
      countryCode: (json['country_code'] as String?) ?? 'RU',
      countryName: (json['country_name'] as String?) ?? 'Россия',
      regionCode: json['region_code'] as String?,
      regionName: json['region_name'] as String?,
      cityCode: json['city_code'] as String?,
      cityName: json['city_name'] as String?,
      isAdmin: (json['is_admin'] as bool?) ?? false,
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
        successfulCapturesCount:
            (statsJson['successful_captures_count'] as num?)?.toInt() ?? 0,
        totalCapturedAreaM2:
            (statsJson['total_captured_area_m2'] as num?)?.toDouble() ?? 0,
        totalVictimsCount:
            (statsJson['total_victims_count'] as num?)?.toInt() ?? 0,
        ownedAreaM2: (statsJson['owned_area_m2'] as num?)?.toDouble() ?? 0,
        profileXp: (statsJson['profile_xp'] as num?)?.toInt() ?? 0,
        profileLevel: (statsJson['profile_level'] as num?)?.toInt() ?? 1,
      ),
    );
  }

  AchievementItem _achievementFromJson(Map<String, dynamic> json) {
    return AchievementItem(
      code: (json['code'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      iconKey: (json['icon_key'] as String?) ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isUnlocked: (json['is_unlocked'] as bool?) ?? false,
      unlockedAt: DateTime.tryParse((json['unlocked_at'] as String?) ?? ''),
    );
  }
}
