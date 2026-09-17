import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_place.dart';
import '../services/saved_place_service.dart';
import 'auth_provider.dart';

final savedPlaceServiceProvider = Provider<SavedPlaceService>((ref) {
  return SavedPlaceService(apiClient: ref.watch(apiClientProvider));
});

final savedPlacesProvider = FutureProvider<List<SavedPlaceItem>>((ref) async {
  return ref.watch(savedPlaceServiceProvider).list();
});
