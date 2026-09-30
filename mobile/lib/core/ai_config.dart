import 'package:flutter/foundation.dart';

/// Base URL for the AI_Id restaurant-recommendation chatbot service.
///
/// Same override pattern as [ApiConfig]: release builds default to the
/// production service behind nginx at `mkka.uz/ai` (path-based routing —
/// shares the main domain's TLS cert instead of needing its own
/// subdomain). Debug/profile runs talk to a locally-run AI_Id instance
/// (`python main.py`, port 5000). Override with
/// `--dart-define=AI_API_BASE_URL=http://192.168.x.x:5000` when testing
/// on a physical device against a local AI_Id instance.
class AiConfig {
  const AiConfig._();

  static const String productionUrl = 'https://mkka.uz/ai';

  static String get baseUrl {
    const override = String.fromEnvironment('AI_API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kReleaseMode) return productionUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }
}
