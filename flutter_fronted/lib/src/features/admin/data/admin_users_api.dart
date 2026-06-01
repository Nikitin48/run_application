import 'package:dio/dio.dart';

class AdminUsersApi {
  AdminUsersApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/admin/users',
      queryParameters: {'query': query, 'limit': limit, 'offset': offset},
    );
    return (res.data ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> banUser(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/users/$userId/ban',
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> unbanUser(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/users/$userId/unban',
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> grantAdmin(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/users/$userId/grant-admin',
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> revokeAdmin(String userId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/users/$userId/revoke-admin',
    );
    return res.data!;
  }
}
