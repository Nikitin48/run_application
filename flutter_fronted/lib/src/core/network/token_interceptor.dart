import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_tokens.dart';
import '../storage/token_storage.dart';
import 'session_expired_listener.dart';

typedef RefreshTokensFn = Future<AuthTokens> Function(String refreshToken);

class TokenInterceptor extends QueuedInterceptorsWrapper {
  TokenInterceptor({
    required this.tokenStorage,
    required this.refreshTokens,
    this.sessionExpiredListener,
  });

  final TokenStorage tokenStorage;
  final RefreshTokensFn refreshTokens;
  final SessionExpiredListener? sessionExpiredListener;

  Future<AuthTokens?> _cachedTokens() => tokenStorage.read();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _cachedTokens();
    if (tokens != null && options.headers['Authorization'] == null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final request = err.requestOptions;

    final is401 = response?.statusCode == 401;
    final alreadyRetried = (request.extra['__retried'] == true);
    final isRefreshCall = request.path.contains('/auth/refresh');

    if (!is401 || alreadyRetried || isRefreshCall) {
      handler.next(err);
      return;
    }

    final tokens = await _cachedTokens();
    if (tokens == null) {
      handler.next(err);
      return;
    }

    try {
      final newTokens = await refreshTokens(tokens.refreshToken);
      await tokenStorage.write(newTokens);

      final dio = err.requestOptions.cancelToken == null
          ? Dio()
          : Dio(); // чистый Dio для повтора запроса; baseUrl уже в requestOptions

      final retryOptions = request.copyWith(
        extra: {...request.extra, '__retried': true},
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${newTokens.accessToken}',
        },
      );

      final retryResponse = await dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await tokenStorage.clear();
      sessionExpiredListener?.onSessionExpired();
      handler.next(err);
    }
  }
}
