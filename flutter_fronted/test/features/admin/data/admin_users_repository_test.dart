import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_application/src/features/admin/data/admin_users_api.dart';
import 'package:run_application/src/features/admin/data/admin_users_repository.dart';

class _FakeAdminUsersApi extends AdminUsersApi {
  _FakeAdminUsersApi() : super(Dio());

  @override
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    return [
      {
        'id': 'user-1',
        'username': 'runner@example.com',
        'display_name': 'Runner',
        'email': 'runner@example.com',
        'avatar_url': null,
        'is_admin': true,
        'is_banned': false,
        'owned_area_m2': 1250.5,
        'created_at': '2026-06-01T10:00:00Z',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> banUser(String userId) async {
    return {
      'user': {
        'id': userId,
        'username': 'runner@example.com',
        'display_name': 'Runner',
        'email': 'runner@example.com',
        'avatar_url': null,
        'is_admin': false,
        'is_banned': true,
        'owned_area_m2': 0,
        'created_at': '2026-06-01T10:00:00Z',
      },
      'revoked_sessions_count': 2,
      'deleted_territories_count': 3,
    };
  }
}

void main() {
  group('AdminUsersRepositoryImpl', () {
    test('parses admin users from API', () async {
      final repo = AdminUsersRepositoryImpl(_FakeAdminUsersApi());

      final users = await repo.searchUsers(query: 'runner');

      expect(users, hasLength(1));
      expect(users.single.id, 'user-1');
      expect(users.single.email, 'runner@example.com');
      expect(users.single.isAdmin, isTrue);
      expect(users.single.isBanned, isFalse);
      expect(users.single.ownedAreaM2, 1250.5);
    });

    test('parses ban side effect counts', () async {
      final repo = AdminUsersRepositoryImpl(_FakeAdminUsersApi());

      final result = await repo.banUser('user-1');

      expect(result.user.isBanned, isTrue);
      expect(result.revokedSessionsCount, 2);
      expect(result.deletedTerritoriesCount, 3);
    });
  });
}
