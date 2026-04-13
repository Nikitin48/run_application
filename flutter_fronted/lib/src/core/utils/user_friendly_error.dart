import 'dart:io';

import 'package:dio/dio.dart';

String toUserFriendlyError(
  Object error, {
  String fallbackMessage = 'Что-то пошло не так. Попробуйте еще раз.',
}) {
  if (error is DioException) {
    final detail = _extractBackendDetail(error.response?.data);
    final mappedDetail = _mapBackendDetail(detail);
    if (mappedDetail != null) return mappedDetail;

    if (_isOfflineError(error)) {
      return 'Нет подключения к интернету. Проверьте сеть и попробуйте снова.';
    }
    if (_isTimeoutError(error)) {
      return 'Сервер долго не отвечает. Попробуйте еще раз.';
    }
    if (detail != null && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    return fallbackMessage;
  }

  final raw = error.toString().trim();
  if (raw.isEmpty) return fallbackMessage;

  final lowered = raw.toLowerCase();
  if (lowered.contains('socketexception') ||
      lowered.contains('failed host lookup') ||
      lowered.contains('network is unreachable')) {
    return 'Нет подключения к интернету. Проверьте сеть и попробуйте снова.';
  }

  final mappedRaw = _mapBackendDetail(raw);
  if (mappedRaw != null) return mappedRaw;
  if (lowered.contains('exception:')) return fallbackMessage;
  return raw;
}

String? _extractBackendDetail(dynamic data) {
  if (data is Map && data['detail'] is String) {
    return (data['detail'] as String).trim();
  }
  return null;
}

bool _isOfflineError(DioException e) {
  if (e.type == DioExceptionType.connectionError) return true;
  final inner = e.error;
  if (inner is SocketException) return true;

  final msg = '${e.message ?? ''} ${inner ?? ''}'.toLowerCase();
  return msg.contains('failed host lookup') ||
      msg.contains('socketexception') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused');
}

bool _isTimeoutError(DioException e) {
  return e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;
}

String? _mapBackendDetail(String? detail) {
  if (detail == null || detail.isEmpty) return null;
  final d = detail.toLowerCase();

  if (d == 'set region in profile first') {
    return 'Для рейтинга по области сначала выберите область в профиле.';
  }
  if (d == 'set city in profile first') {
    return 'Для рейтинга по городу сначала выберите область и город в профиле.';
  }
  if (d == 'region_code is required for city_code') {
    return 'Сначала выберите область, затем город.';
  }
  if (d == 'invalid region_code') {
    return 'Выбранная область недоступна. Выберите область заново.';
  }
  if (d == 'invalid city_code') {
    return 'Выбранный город недоступен. Выберите город заново.';
  }
  return null;
}
