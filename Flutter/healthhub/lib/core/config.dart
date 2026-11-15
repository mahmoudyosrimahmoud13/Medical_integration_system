import 'package:flutter/foundation.dart';

import 'server/server_settings.dart';

/// Where the API lives.
///
/// 1. The address chosen in the app (first start, login screen or profile). This is the normal case.
/// 2. An address built into the app: flutter build apk --dart-define=API_BASE_URL=https://...
///    It is offered as the suggestion on the server screen.
/// 3. For development: the Android emulator reaches the computer at 10.0.2.2, everything else at localhost.
class AppConfig {
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// The built-in address, unless it is the placeholder that CI uses when none was set.
  static String? get builtInAddress {
    if (_fromEnv.isEmpty || _fromEnv.contains('example.com')) return null;
    return ServerSettings.normalize(_fromEnv);
  }

  static String get apiBaseUrl {
    final chosen = ServerSettings.url.value;
    if (chosen != null && chosen.isNotEmpty) return chosen;
    final builtIn = builtInAddress;
    if (builtIn != null) return builtIn;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8020';
    return 'http://localhost:8020';
  }

  static String get apiV1 => '$apiBaseUrl/api/v1';
}
