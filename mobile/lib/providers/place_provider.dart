import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import 'auth_provider.dart';

const fallbackLat = 41.311081;
const fallbackLng = 69.240562;

final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService(apiClient: ref.watch(apiClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Null means GPS wasn't available (permission denied, service off, or
/// timed out) — callers fall back to [fallbackLat]/[fallbackLng] and should
/// treat any resulting distance as approximate, not from the user's actual
/// position.
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentPosition();
});

final nearbyPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  return ref
      .watch(placeServiceProvider)
      .listNearby(
        lat: position?.latitude ?? fallbackLat,
        lng: position?.longitude ?? fallbackLng,
      );
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
