import 'package:geolocator/geolocator.dart';

/// Thrown by callers when [LocationService.getCurrentPosition] returns null,
/// so the UI can show an actionable message instead of silently using a
/// wrong location.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException();
}

/// Wraps device GPS access. Returns null on any failure (permission denied,
/// location services off, timeout) — callers must surface this to the user
/// rather than silently substituting a fixed reference point.
class LocationService {
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
