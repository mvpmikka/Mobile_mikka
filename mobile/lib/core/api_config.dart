import 'package:flutter/foundation.dart';

/// Base URL for the Mikka backend.
///
/// Android emulators can't reach the host machine via `localhost` — they
/// need the special `10.0.2.2` alias instead. iOS simulators and desktop
/// runs talk to `localhost` directly. Override with
/// `--dart-define=API_BASE_URL=http://192.168.x.x:3000` when testing on a
/// physical device on the same network.
class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3112';
    }
    return 'http://localhost:3112';
  }
}
