import '../domain/admin_user.dart';
import '../domain/repositories/admin_users_repository.dart';
import 'admin_users_api.dart';

class AdminUsersRepositoryImpl implements AdminUsersRepository {
  AdminUsersRepositoryImpl(this._api);

  final AdminUsersApi _api;

  @override
  Future<List<AdminUser>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _api.searchUsers(
      query: query,
      limit: limit,
      offset: offset,
    );
    return rows.map(_userFromJson).toList(growable: false);
  }

  @override
  Future<AdminUserActionResult> banUser(String userId) async {
    final json = await _api.banUser(userId);
    return _actionResultFromJson(json);
  }

  @override
  Future<AdminUser> unbanUser(String userId) async {
    return _userFromJson(await _api.unbanUser(userId));
  }

  @override
  Future<AdminUser> grantAdmin(String userId) async {
    return _userFromJson(await _api.grantAdmin(userId));
  }

  @override
  Future<AdminUser> revokeAdmin(String userId) async {
    return _userFromJson(await _api.revokeAdmin(userId));
  }

  AdminUserActionResult _actionResultFromJson(Map<String, dynamic> json) {
    return AdminUserActionResult(
      user: _userFromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      revokedSessionsCount:
          (json['revoked_sessions_count'] as num?)?.toInt() ?? 0,
      deletedTerritoriesCount:
          (json['deleted_territories_count'] as num?)?.toInt() ?? 0,
    );
  }

  AdminUser _userFromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isAdmin: (json['is_admin'] as bool?) ?? false,
      isBanned: (json['is_banned'] as bool?) ?? false,
      ownedAreaM2: (json['owned_area_m2'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
