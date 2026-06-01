import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_application/src/core/utils/user_friendly_error.dart';

void main() {
  group('toUserFriendlyError', () {
    test('maps speed anticheat backend detail', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/runs/finish'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/runs/finish'),
          statusCode: 422,
          data: {'detail': 'run speed invalid'},
        ),
      );

      expect(
        toUserFriendlyError(error),
        'Пробежка не засчитана: скорость на части маршрута слишком высокая.',
      );
    });
  });
}
