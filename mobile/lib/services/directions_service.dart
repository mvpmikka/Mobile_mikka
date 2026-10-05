import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/directions_config.dart';
import '../models/route_info.dart';

/// Thrown when geocoding or every transport mode fails, so the UI can show
/// one clear message instead of silently rendering an empty map.
class DirectionsException implements Exception {
  const DirectionsException(this.message);

  final String message;
}

/// Calls Google's Geocoding and Directions HTTP APIs directly (no SDK —
/// these aren't exposed by `google_maps_flutter`).
class DirectionsService {
  DirectionsService()
    : _dio = Dio(BaseOptions(baseUrl: 'https://maps.googleapis.com/maps/api'));

  final Dio _dio;

  Future<LatLng> geocodeAddress(String address) async {
    final response = await _dio.get(
      '/geocode/json',
      queryParameters: {'address': address, 'key': DirectionsConfig.apiKey},
    );
    final data = response.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? const [];
    if (data['status'] != 'OK' || results.isEmpty) {
      throw const DirectionsException("Manzil topilmadi.");
    }
    final location =
        (results.first as Map<String, dynamic>)['geometry']['location'] as Map<String, dynamic>;
    return LatLng((location['lat'] as num).toDouble(), (location['lng'] as num).toDouble());
  }

  /// Fetches driving/walking/bicycling/transit routes and fills in
  /// [TransportMode.scooter], [TransportMode.bus] and [TransportMode.metro]
  /// from them. A mode missing from the result means Google had no route
  /// for it (e.g. no transit coverage in the area) — the caller should just
  /// not show a chip for it, not treat it as an error.
  Future<Map<TransportMode, RouteInfo>> fetchAllRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final driving = await _tryFetchRoute(origin, destination, 'driving');
    final walking = await _tryFetchRoute(origin, destination, 'walking');
    final bicycling = await _tryFetchRoute(origin, destination, 'bicycling');
    final transit = await _tryFetchRoute(origin, destination, 'transit');

    final routes = <TransportMode, RouteInfo>{};
    if (driving != null) routes[TransportMode.car] = driving;
    if (walking != null) routes[TransportMode.walking] = walking;
    if (bicycling != null) {
      routes[TransportMode.bicycle] = bicycling;
      routes[TransportMode.scooter] = RouteInfo(
        distanceKm: bicycling.distanceKm,
        // Scooters cruise faster than a bicycle on the same route; 0.6x the
        // cycling time is a rough approximation, not a real routing profile
        // (Google Directions has no scooter mode to ask for one).
        durationMinutes: (bicycling.durationMinutes * 0.6).round().clamp(1, 1 << 30),
        points: bicycling.points,
      );
    }
    if (transit != null) {
      // Google's "transit" mode doesn't distinguish bus from metro, so both
      // chips show the same result.
      routes[TransportMode.bus] = transit;
      routes[TransportMode.metro] = transit;
    }

    if (routes.isEmpty) {
      throw const DirectionsException("Yo'nalish topilmadi.");
    }
    return routes;
  }

  Future<RouteInfo?> _tryFetchRoute(LatLng origin, LatLng destination, String googleMode) async {
    try {
      final response = await _dio.get(
        '/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': googleMode,
          'key': DirectionsConfig.apiKey,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>? ?? const [];
      if (data['status'] != 'OK' || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>;
      final leg = legs.first as Map<String, dynamic>;
      final distanceMeters = (leg['distance']['value'] as num).toDouble();
      final durationSeconds = (leg['duration']['value'] as num).toDouble();
      final polyline = route['overview_polyline']['points'] as String;

      return RouteInfo(
        distanceKm: distanceMeters / 1000,
        durationMinutes: (durationSeconds / 60).round(),
        points: _decodePolyline(polyline),
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes Google's polyline encoding (standard algorithm, no package
  /// pulled in for the ~15 lines it takes).
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var result = 1;
      var shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      result = 1;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
