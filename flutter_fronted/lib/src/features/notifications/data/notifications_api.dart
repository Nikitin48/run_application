import 'package:dio/dio.dart';

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> last() async {
    final res = await _dio.get<Map<String, dynamic>>('/notifications/last');
    return res.data!;
  }
}


