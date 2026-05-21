import 'package:flutter/foundation.dart';

// Note: we intentionally avoid importing `dart:io` on web.
// For this project we focus on Android/iOS; web can be configured via dart-define.

class ApiConfig {
  static const String _dartDefineBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Base URL for backend API.
  ///
  /// Recommended:
  /// - Android Emulator: default `http://10.0.2.2:8000`
  /// - iOS Simulator: default `http://127.0.0.1:8000`
  /// - Physical device: pass `--dart-define=API_BASE_URL=http://<MAC_IP>:8000`
  static String get baseUrl {
    if (_dartDefineBaseUrl.isNotEmpty) return _dartDefineBaseUrl;

    // Conservative defaults:
    // - If running on Android emulator, 127.0.0.1 points to the emulator itself, so use 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
