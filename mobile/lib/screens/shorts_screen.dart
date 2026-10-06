import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../core/api_exception.dart';
import '../models/short.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/short_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coming_soon.dart';
import 'search_screen.dart';

enum _FeedTab { friends, trending }

// Vertical TikTok/Reels-style feed matching the Figma reference screenshots
// (mobile/assets/icon/Video Item 2-5.png) — backed by GET /shorts/feed via
// shortFeedProvider. Like and Follow are wired to the backend; the
// Friends/Trending toggle is cosmetic (both read the same already-blended
// feed); comment/bookmark/share/music are v1 stubs (showComingSoon).
class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key});

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;
  _FeedTab _feedTab = _FeedTab.trending;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, int itemCount) {
    setState(() => _currentIndex = index);
    if (index >= itemCount - 2) {
      ref.read(shortFeedProvider.notifier).loadMore();
    }
  }

  void _openSearch() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(shortFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          feedAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
            error: (error, _) => _buildMessage(
              context,
              "Yuklab bo'lmadi",
              onRetry: () => ref.invalidate(shortFeedProvider),
            ),
            data: (shorts) {
              if (shorts.isEmpty) {
                return _buildMessage(context, 'Hali videolar yo\'q');
              }
              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: shorts.length,
                onPageChanged: (index) => _onPageChanged(index, shorts.length),
                itemBuilder: (context, index) {
                  return _ShortPage(
                    short: shorts[index],
                    isActive: index == _currentIndex,
                    showScrollHint: index == 0,
                    onLike: () => ref.read(shortFeedProvider.notifier).toggleLike(shorts[index].id),
                  );
                },
              );
            },
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  _buildFeedToggle(context),
                  const Spacer(),
                  _RoundGlassButton(icon: Icons.search, onTap: _openSearch),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFeedToggleSegment(context, _FeedTab.friends, 'Friends'),
          _buildFeedToggleSegment(context, _FeedTab.trending, 'Trending'),
        ],
      ),
    );
  }

  Widget _buildFeedToggleSegment(BuildContext context, _FeedTab tab, String label) {
    final isSelected = tab == _feedTab;
    return GestureDetector(
      onTap: () => setState(() => _feedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text, {VoidCallback? onRetry}) {
    // top: 100 keeps this clear of the floating Friends/Trending toggle +
    // search button overlaid near the top of the screen (see build()),
    // instead of Center()-ing over the whole stack and risking overlap on
    // shorter screens.
    return Positioned.fill(
      top: 100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Qayta urinish', style: TextStyle(color: AppColors.orange)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _ShortPage extends ConsumerStatefulWidget {
  const _ShortPage({
    required this.short,
    required this.isActive,
    required this.onLike,
    required this.showScrollHint,
  });

  final Short short;
  final bool isActive;
  final bool showScrollHint;
  final VoidCallback onLike;

  @override
  ConsumerState<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends ConsumerState<_ShortPage> {
  VideoPlayerController? _controller;
  bool? _isFollowing;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _ShortPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _syncPlayback();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.short.videoUrl));
    await controller.initialize();
    await controller.setLooping(true);
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    _syncPlayback();
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
    }
  }

  Future<void> _toggleFollow() async {
    final username = widget.short.user.username;
    if (username == null || _followBusy) return;

    final wasFollowing = _isFollowing ?? false;
    setState(() {
      _followBusy = true;
      _isFollowing = !wasFollowing;
    });
    try {
      final service = ref.read(followServiceProvider);
      if (wasFollowing) {
        await service.unfollow(username);
      } else {
        await service.follow(username);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFollowing = wasFollowing);
      final message = e is ApiException ? e.message : "Amalni bajarib bo'lmadi";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.orange),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final short = widget.short;
    final currentUserId = ref.watch(authControllerProvider).value?.user?.id;
    final isOwnVideo = currentUserId != null && currentUserId == short.user.id;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (short.thumbnailUrl != null)
          Image.network(short.thumbnailUrl!, fit: BoxFit.cover),
        if (controller != null && controller.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 86,
          bottom: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (short.place != null) ...[
                _LocationPill(label: short.place!.name),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '@${short.user.username ?? short.user.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: AppColors.orange, size: 16),
                ],
              ),
              if (short.caption != null) ...[
                const SizedBox(height: 6),
                Text(
                  short.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => showComingSoon(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note, color: Colors.white, size: 13),
                      SizedBox(width: 6),
                      Text(
                        'Original audio',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showScrollHint)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCROLL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
              ],
            ),
          ),
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            children: [
              if (!isOwnVideo && short.user.username != null) ...[
                _FollowAvatar(
                  avatarUrl: short.user.avatarUrl,
                  isFollowing: _isFollowing ?? false,
                  onTap: _toggleFollow,
                ),
                const SizedBox(height: 18),
              ],
              _ActionButton(
                icon: short.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                iconColor: short.isLikedByMe ? AppColors.orange : Colors.white,
                label: '${short.likeCount}',
                onTap: widget.onLike,
              ),
              const SizedBox(height: 18),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                label: 'Izoh',
                onTap: () => showComingSoon(context),
              ),
              const SizedBox(height: 18),
              _ActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: () => showComingSoon(context),
              ),
              const SizedBox(height: 18),
              _ActionButton(
                icon: Icons.share_outlined,
                label: null,
                onTap: () => showComingSoon(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowAvatar extends StatelessWidget {
  const _FollowAvatar({
    required this.avatarUrl,
    required this.isFollowing,
    required this.onTap,
  });

  final String? avatarUrl;
  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.orange,
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
              ),
            ),
            if (!isFollowing)
              Positioned(
                bottom: 0,
                left: 12,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
