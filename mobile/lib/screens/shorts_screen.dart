import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/short.dart';
import '../providers/short_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coming_soon.dart';
import 'shorts_capture_screen.dart';

// Vertical TikTok/Reels-style feed — backed by GET /shorts/feed via
// shortFeedProvider. Only Like is wired to the backend; comment/bookmark/
// share are v1 stubs (showComingSoon).
class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key});

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

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

  Future<void> _openCapture() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ShortsCaptureScreen()),
    );
    if (created == true) {
      ref.invalidate(shortFeedProvider);
    }
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
                    onLike: () => ref.read(shortFeedProvider.notifier).toggleLike(shorts[index].id),
                  );
                },
              );
            },
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _openCapture,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text, {VoidCallback? onRetry}) {
    return Center(
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
    );
  }
}

class _ShortPage extends StatefulWidget {
  const _ShortPage({required this.short, required this.isActive, required this.onLike});

  final Short short;
  final bool isActive;
  final VoidCallback onLike;

  @override
  State<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<_ShortPage> {
  VideoPlayerController? _controller;

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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.short.thumbnailUrl != null)
          Image.network(widget.short.thumbnailUrl!, fit: BoxFit.cover),
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
              stops: [0.6, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 90,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.short.user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (widget.short.place != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.short.place!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.short.caption != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.short.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            children: [
              _ActionButton(
                icon: widget.short.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                iconColor: widget.short.isLikedByMe ? AppColors.orange : Colors.white,
                label: '${widget.short.likeCount}',
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
                label: 'Saqlash',
                onTap: () => showComingSoon(context),
              ),
              const SizedBox(height: 18),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Ulashish',
                onTap: () => showComingSoon(context),
              ),
            ],
          ),
        ),
      ],
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
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
