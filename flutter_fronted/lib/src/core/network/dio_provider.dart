import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_api.dart';
import '../../features/auth/domain/auth_tokens.dart';
import 'session_expired_listener.dart';
import 'token_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    TokenInterceptor(
      tokenStorage: ref.read(tokenStorageProvider),
      refreshTokens: (refreshToken) async {
        // Отдельный экземпляр Dio без интерцепторов, чтобы избежать рекурсии при refresh.
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
        final api = AuthApi(refreshDio);
        final tokens = await api.refresh(refreshToken);
        return tokens;
      },
      sessionExpiredListener: SessionExpiredCallback(() {
        ref.read(authControllerProvider.notifier).logout();
      }),
    ),
  );

  return dio;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  // Опции по умолчанию; при необходимости можно настроить под iOS accessibility.
  final storage = FlutterSecureStorage();
  return TokenStorage(storage);
});

// Вспомогательные провайдеры
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authTokensProvider = FutureProvider<AuthTokens?>((ref) async {
  return ref.read(tokenStorageProvider).read();
});


