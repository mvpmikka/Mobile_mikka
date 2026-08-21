import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend.dart';
import '../models/public_profile.dart';
import '../services/follow_service.dart';
import 'auth_provider.dart';
import 'user_search_provider.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService(apiClient: ref.watch(apiClientProvider));
});

final publicProfileProvider = FutureProvider.family<PublicProfile, String>((
  ref,
  username,
) async {
  return ref.watch(userServiceProvider).getPublicProfile(username);
});

final followersProvider = FutureProvider.family<List<Friend>, String>((
  ref,
  username,
) async {
  return ref.watch(followServiceProvider).listFollowers(username);
});

final followingProvider = FutureProvider.family<List<Friend>, String>((
  ref,
  username,
) async {
  return ref.watch(followServiceProvider).listFollowing(username);
});
