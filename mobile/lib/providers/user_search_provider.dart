import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_search_result.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(apiClient: ref.watch(apiClientProvider));
});

/// Backend requires at least 2 characters — shorter queries just return an
/// empty result without a network call.
final userSearchProvider = FutureProvider.family<List<UserSearchResult>, String>((
  ref,
  query,
) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return const [];
  return ref.watch(userServiceProvider).search(trimmed);
});
