import 'package:dio/dio.dart';

class TerritoriesApi {
  TerritoriesApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getTerritories({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/territories',
      queryParameters: {
        'minLng': minLng,
        'minLat': minLat,
        'maxLng': maxLng,
        'maxLat': maxLat,
      },
    );
    return res.data!;
  }
}


