import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/badge.dart' as models;
import '../models/public_profile.dart';
import '../providers/badge_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/post_provider.dart';
import '../providers/review_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/segmented_tab_bar.dart';
import 'message_thread_screen.dart';

/// Another user's profile — Posts / Reviews / Titles tabs, Follow/Unfollow
/// + Message actions. Distinct from ProfileScreen, which is the signed-in
/// user's own profile (My Posts / Memories / Badges, Edit Profile).
class FriendProfileScreen extends ConsumerStatefulWidget {
  const FriendProfileScreen({super.key, required this.username});

  final String username;

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  int _selectedTab = 0;
  bool _isFollowActionPending = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.username));

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
        title: Text(
          '@${widget.username}',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
          error: (error, _) => Center(
            child: Text(
              error is ApiException ? error.message : 'Profilni yuklab bo\'lmadi',
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          ),
          data: (profile) => _buildProfile(context, profile),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, PublicProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.person, color: Colors.white, size: 46),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${profile.username}',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatItem(label: 'Followers', value: '${profile.followersCount}'),
              _StatItem(label: 'Following', value: '${profile.followingCount}'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: profile.isFollowedByMe
                      ? OutlinedButton(
                          onPressed: _isFollowActionPending
                              ? null
                              : () => _toggleFollow(profile, follow: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.darkText(context),
                            side: BorderSide(color: AppColors.fieldBorder(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Unfollow',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _isFollowActionPending
                              ? null
                              : () => _toggleFollow(profile, follow: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Follow',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _openChat(profile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkText(context),
                      side: BorderSide(color: AppColors.fieldBorder(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Message',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SegmentedTabBar(
            labels: const ['Posts', 'Reviews', 'Titles'],
            selectedIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 16),
          _buildTabContent(profile.username),
        ],
      ),
    );
  }

  Widget _buildTabContent(String username) {
    switch (_selectedTab) {
      case 0:
        return _PostsGrid(username: username);
      case 1:
        return _ReviewsList(username: username);
      default:
        return _TitlesList(username: username);
    }
  }

  Future<void> _toggleFollow(PublicProfile profile, {required bool follow}) async {
    setState(() => _isFollowActionPending = true);
    try {
      final service = ref.read(followServiceProvider);
      if (follow) {
        await service.follow(profile.username);
      } else {
        await service.unfollow(profile.username);
      }
      ref.invalidate(publicProfileProvider(profile.username));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    } finally {
      if (mounted) setState(() => _isFollowActionPending = false);
    }
  }

  Future<void> _openChat(PublicProfile profile) async {
    try {
      final conversation = await ref
          .read(chatServiceProvider)
          .openPrivateConversation(profile.id);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessageThreadScreen(
            conversationId: conversation.id,
            title: profile.displayName,
            otherUserId: profile.id,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }
}

class _PostsGrid extends ConsumerWidget {
  const _PostsGrid({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsByUsernameProvider(username));
    return posts.when(
      data: (items) {
        if (items.isEmpty) return _EmptyMessage(text: 'Hali postlar yo\'q');
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final url = items[index].coverImageUrl;
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: AppColors.surface(context),
                child: url != null && url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.mutedText(context),
                        ),
                      )
                    : Icon(Icons.image_outlined, color: AppColors.mutedText(context)),
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyMessage(text: 'Postlarni yuklab bo\'lmadi'),
    );
  }
}

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsByUsernameProvider(username));
    return reviews.when(
      data: (items) {
        if (items.isEmpty) return _EmptyMessage(text: 'Hali sharhlar yo\'q');
        return Column(
          children: items.map((review) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.place.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText(context),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.comment!,
                      style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyMessage(text: 'Sharhlarni yuklab bo\'lmadi'),
    );
  }
}

class _TitlesList extends ConsumerWidget {
  const _TitlesList({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesByUsernameProvider(username));
    return badges.when(
      data: (items) {
        if (items.isEmpty) return _EmptyMessage(text: 'Hali unvonlar yo\'q');
        return Column(children: items.map((b) => _TitleTile(badge: b)).toList());
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyMessage(text: 'Unvonlarni yuklab bo\'lmadi'),
    );
  }
}

class _TitleTile extends StatelessWidget {
  const _TitleTile({required this.badge});

  final models.UserBadge badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: badge.iconUrl != null && badge.iconUrl!.isNotEmpty
                ? Image.network(
                    badge.iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.emoji_events, color: Colors.white, size: 22),
                  )
                : const Icon(Icons.emoji_events, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.mutedText(context))),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
        ],
      ),
    );
  }
}
