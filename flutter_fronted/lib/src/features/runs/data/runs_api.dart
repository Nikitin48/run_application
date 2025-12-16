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
}


