import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import 'auth_provider.dart';

final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService(apiClient: ref.watch(apiClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Null means GPS wasn't available (permission denied, service off, or
/// timed out) — [nearbyPlacesProvider] turns that into a
/// [LocationUnavailableException] rather than guessing a location.
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentPosition();
});

final nearbyPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) {
    throw const LocationUnavailableException();
  }
  return ref
      .watch(placeServiceProvider)
      .listNearby(lat: position.latitude, lng: position.longitude);
});

final placeDetailProvider = FutureProvider.family<PlaceDetail, String>((
  ref,
  placeId,
) async {
  return ref.watch(placeServiceProvider).getDetail(placeId);
});

final placeRatingProvider = FutureProvider.family<PlaceRating, String>((
  ref,
  placeId,
) async {
  return ref.watch(placeServiceProvider).getRating(placeId);
});
