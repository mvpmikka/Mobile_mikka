import 'package:flutter/foundation.dart';

/// Base URL for the Mikka backend.
///
/// Release builds (the APKs that actually get installed on real devices)
/// default to the production backend on Render. Debug/profile runs keep
/// talking to a local backend: Android emulators can't reach the host
/// machine via `localhost` — they need the special `10.0.2.2` alias
/// instead — while iOS simulators and desktop runs use `localhost`
/// directly. Override any of this with
/// `--dart-define=API_BASE_URL=http://192.168.x.x:3000` when testing on a
/// physical device against a local backend.
class ApiConfig {
  const ApiConfig._();

  static const String productionUrl = 'https://mobile-mikka.onrender.com';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kReleaseMode) return productionUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3112';
    }
    return 'http://localhost:3112';
  }
}
