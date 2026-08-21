import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_activity.dart';
import 'chat_provider.dart';

/// Powers the friends-list distance/online-status row — one backend call
/// covering every friend (see `FriendshipService.listActivity`), distinct
/// from `friendLocationsProvider` which fetches raw check-in coordinates
/// for map pin placement.
final friendActivityProvider = FutureProvider<List<FriendActivity>>((
  ref,
) async {
  return ref.watch(friendshipServiceProvider).listActivity();
});
