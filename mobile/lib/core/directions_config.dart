/// API key for Google Geocoding/Directions, called directly from Dart via
/// HTTP (not through the native Maps SDK). The keys already baked into
/// `AndroidManifest.xml`/`AppDelegate.swift` are restricted to the native
/// Maps SDK (Android package + SHA1 / iOS bundle ID) and will be rejected by
/// a plain HTTP call, so this needs its own key with no such restriction.
/// Pass it with `--dart-define=DIRECTIONS_API_KEY=...`.
class DirectionsConfig {
  const DirectionsConfig._();

  static String get apiKey => const String.fromEnvironment('DIRECTIONS_API_KEY');
}
