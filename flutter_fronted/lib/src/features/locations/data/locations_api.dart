import 'package:dio/dio.dart';

class LocationsApi {
  LocationsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getCountries() async {
    final res = await _dio.get<List<dynamic>>('/locations/countries');
    return (res.data ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> searchRegions({
    required String countryCode,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/locations/regions',
      queryParameters: {
        'country_code': countryCode,
        'query': query,
        'limit': limit,
        'offset': offset,
      },
    );
    return (res.data ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> searchCities({
    required String countryCode,
    required String regionCode,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/locations/cities',
      queryParameters: {
        'country_code': countryCode,
        'region_code': regionCode,
        'query': query,
        'limit': limit,
        'offset': offset,
      },
    );
    return (res.data ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }
}
