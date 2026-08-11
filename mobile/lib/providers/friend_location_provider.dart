import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/check_in.dart';
import '../services/check_in_service.dart';
import 'auth_provider.dart';
import 'chat_provider.dart';

final checkInServiceProvider = Provider<CheckInService>((ref) {
  return CheckInService(apiClient: ref.watch(apiClientProvider));
});

/// Each friend's most recent check-in, keyed by friend (user) id — used to
/// place friends on the map at a real location instead of a fake one.
/// Friends with no visible check-in are simply absent from the map, not
/// given a fake position.
final friendLocationsProvider = FutureProvider<Map<String, PublicCheckIn>>((
  ref,
) async {
  final friends = await ref.watch(friendsProvider.future);
  final service = ref.watch(checkInServiceProvider);

  final result = <String, PublicCheckIn>{};
  await Future.wait(
    friends.map((friend) async {
      final username = friend.profile.username;
      if (username == null) return;
      final checkIn = await service.getLatestForUser(username);
      if (checkIn != null) {
        result[friend.profile.id] = checkIn;
      }
    }),
  );
  return result;
});
