import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/badge.dart';
import '../services/badge_service.dart';
import 'auth_provider.dart';

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService(apiClient: ref.watch(apiClientProvider));
});

final badgesByUsernameProvider = FutureProvider.family<List<UserBadge>, String>((
  ref,
  username,
) async {
  return ref.watch(badgeServiceProvider).listForUser(username);
});
