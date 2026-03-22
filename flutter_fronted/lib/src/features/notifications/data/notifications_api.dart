import 'package:dio/dio.dart';

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> last() async {
    final res = await _dio.get<Map<String, dynamic>>('/notifications/last');
    return res.data!;
  }

  Future<Map<String, dynamic>> history({int limit = 10}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'limit': limit},
    );
    return res.data!;
  }

  Future<void> registerPushToken({
    required String platform,
    required String token,
    String? appVersion,
    String? deviceId,
  }) async {
    await _dio.post<void>(
      '/push-tokens',
      data: {
        'platform': platform,
        'token': token,
        'app_version': appVersion,
        'device_id': deviceId,
      },
    );
  }

  Future<void> unregisterPushToken(String token) async {
    await _dio.delete<void>(
      '/push-tokens',
      data: {'token': token},
    );
  }
}


