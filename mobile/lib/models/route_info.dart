import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Transport modes shown on the directions screen. Google Directions has no
/// native "scooter" profile and does not separate bus from metro (both come
/// back as the generic "transit" mode) — [DirectionsService.fetchAllRoutes]
/// derives [scooter] from the bicycling result and reuses the single
/// transit result for both [bus] and [metro].
enum TransportMode { car, walking, bicycle, scooter, bus, metro }

/// Distance/time/path for one [TransportMode] between two points.
class RouteInfo {
  const RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.points,
  });

  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> points;
}
