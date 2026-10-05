import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/short.dart';
import '../services/short_service.dart';
import 'auth_provider.dart';

final shortServiceProvider = Provider<ShortService>((ref) {
  return ShortService(apiClient: ref.watch(apiClientProvider));
});

const _shortFeedPageLimit = 10;

/// Paginated Shorts feed with optimistic like-toggle — a plain FutureProvider
/// can't hold "page 2 appended to page 1" state or revert a failed like, so
/// this uses AsyncNotifier instead (same reasoning noted in the Shorts plan).
class ShortFeedNotifier extends AsyncNotifier<List<Short>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<Short>> build() async {
    _page = 1;
    _hasMore = true;
    final result = await ref.read(shortServiceProvider).getFeed(
      page: _page,
      limit: _shortFeedPageLimit,
    );
    _hasMore = result.items.length >= _shortFeedPageLimit;
    return result.items;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;

    _isLoadingMore = true;
    try {
      final nextPage = _page + 1;
      final result = await ref.read(shortServiceProvider).getFeed(
        page: nextPage,
        limit: _shortFeedPageLimit,
      );
      _page = nextPage;
      _hasMore = result.items.length >= _shortFeedPageLimit;
      state = AsyncData([...current, ...result.items]);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> toggleLike(String id) async {
    final current = state.value;
    if (current == null) return;

    final index = current.indexWhere((short) => short.id == id);
    if (index == -1) return;
    final short = current[index];
    final optimistic = short.copyWith(
      isLikedByMe: !short.isLikedByMe,
      likeCount: short.isLikedByMe ? short.likeCount - 1 : short.likeCount + 1,
    );
    state = AsyncData([
      ...current.sublist(0, index),
      optimistic,
      ...current.sublist(index + 1),
    ]);

    try {
      final service = ref.read(shortServiceProvider);
      if (optimistic.isLikedByMe) {
        await service.like(id);
      } else {
        await service.unlike(id);
      }
    } catch (_) {
      final reverted = state.value;
      if (reverted == null) return;
      final revertIndex = reverted.indexWhere((s) => s.id == id);
      if (revertIndex == -1) return;
      state = AsyncData([
        ...reverted.sublist(0, revertIndex),
        short,
        ...reverted.sublist(revertIndex + 1),
      ]);
      rethrow;
    }
  }
}

final shortFeedProvider = AsyncNotifierProvider<ShortFeedNotifier, List<Short>>(
  ShortFeedNotifier.new,
);
