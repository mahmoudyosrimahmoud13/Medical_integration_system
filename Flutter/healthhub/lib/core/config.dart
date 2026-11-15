import 'package:flutter/foundation.dart';

/// Where the API lives. Override with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
/// Defaults: Android emulator reaches the computer at 10.0.2.2, everything else at localhost.
class AppConfig {
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String get apiV1 => '$apiBaseUrl/api/v1';
}
