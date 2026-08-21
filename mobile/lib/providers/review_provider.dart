import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../services/review_service.dart';
import 'auth_provider.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(apiClient: ref.watch(apiClientProvider));
});

final reviewsByUsernameProvider = FutureProvider.family<List<UserReview>, String>((
  ref,
  username,
) async {
  return ref.watch(reviewServiceProvider).getForUser(username);
});
