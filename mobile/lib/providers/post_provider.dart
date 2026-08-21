import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import 'auth_provider.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService(apiClient: ref.watch(apiClientProvider));
});

final postsByUsernameProvider = FutureProvider.family<List<Post>, String>((
  ref,
  username,
) async {
  return ref.watch(postServiceProvider).getForUser(username);
});

final memoriesProvider = FutureProvider<List<Memory>>((ref) async {
  return ref.watch(postServiceProvider).getMemories();
});
