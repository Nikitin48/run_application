import 'package:dio/dio.dart';

import '../domain/run_models.dart';

class RunsApi {
  RunsApi(this._dio);

  final Dio _dio;

  Future<FinishRunResponse> finish(FinishRunRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/runs/finish',
      data: request.toJson(),
    );
    return FinishRunResponse.fromJson(res.data!);
  }

  Future<List<RunHistoryItem>> history({int limit = 50, int offset = 0}) async {
    final res = await _dio.get<List<dynamic>>(
      '/runs/history',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final rows = res.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => RunHistoryItem.fromJson(row))
        .toList(growable: false);
  }
}
