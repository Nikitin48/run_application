import 'package:dio/dio.dart';

import '../domain/auth_tokens.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(res.data!);
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'display_name': displayName},
    );
    return AuthTokens.fromJson(res.data!);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthTokens.fromJson(res.data!);
  }
}
