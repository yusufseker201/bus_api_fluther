import 'package:flutter/foundation.dart';

/// Central place for runtime configuration.
///
/// For Android emulator, the Django host is usually reachable via 10.0.2.2.
/// Override with:
///   flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000/api
class AppConfig {
  static String get apiBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      final base = Uri.base;
      final isLocalHost = base.host == 'localhost' || base.host == '127.0.0.1';

      // `flutter run -d chrome` serves the app from a random localhost port.
      // In that case `/api` points to the Flutter dev server instead of Django.
      if (isLocalHost && base.port != 8000) {
        return '${base.scheme}://${base.host}:8000/api';
      }

      return '/api';
    }

    return 'http://10.0.2.2:8000/api';
  }

  static String get authHeaderScheme {
    const configured = String.fromEnvironment('AUTH_HEADER_SCHEME', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    return 'auto';
  }
}
