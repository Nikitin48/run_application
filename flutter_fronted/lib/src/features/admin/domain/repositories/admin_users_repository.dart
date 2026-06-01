import '../admin_user.dart';

abstract class AdminUsersRepository {
  Future<List<AdminUser>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  });

  Future<AdminUserActionResult> banUser(String userId);

  Future<AdminUser> unbanUser(String userId);

  Future<AdminUser> grantAdmin(String userId);

  Future<AdminUser> revokeAdmin(String userId);
}
