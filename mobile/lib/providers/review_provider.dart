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

/// Admin "Sharhlar" screen — fetched in one large page and filtered/searched
/// client-side (the backend list endpoint takes only page/limit, see
/// ReviewController.list).
final placeReviewListProvider =
    FutureProvider.autoDispose.family<PlaceReviewPage, String>((ref, placeId) async {
  return ref.watch(reviewServiceProvider).listByPlace(placeId, limit: 100);
});
