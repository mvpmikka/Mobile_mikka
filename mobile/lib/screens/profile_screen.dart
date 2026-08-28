import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/badge.dart' as models;
import '../providers/auth_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/friend_location_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mikka_logo.dart';
import '../widgets/segmented_tab_bar.dart';
import 'admin/admin_panel_screen.dart';
import 'conversations_screen.dart';
import 'create_post_screen.dart';
import 'edit_profile_screen.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'shorts_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _selectedNavIndex = 4;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value?.user;
    final avatarUrl = user?.avatarUrl;
    final displayName = user?.fullName ?? user?.username ?? '';
    final username = user?.username ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      );
                      if (created == true && username.isNotEmpty) {
                        ref.invalidate(postsByUsernameProvider(username));
                      }
                    },
                    child: Icon(Icons.add_box_outlined, color: AppColors.darkText(context)),
                  ),
                  const Expanded(
                    child: Center(child: MikkaLogo(height: 28)),
                  ),
                  Icon(Icons.settings_outlined, color: AppColors.darkText(context)),
                ],
              ),
              const SizedBox(height: 20),
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
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 46,
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                    ),
                    if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkText(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatItem(label: 'Followers', value: '${user?.followersCount ?? 0}'),
                  _StatItem(label: 'Following', value: '${user?.followingCount ?? 0}'),
                  Consumer(
                    builder: (context, ref, _) {
                      final count = ref.watch(myCheckInCountProvider);
                      return _StatItem(
                        label: 'Check-ins',
                        value: count.maybeWhen(data: (v) => '$v', orElse: () => '—'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText(context),
                          side: BorderSide(color: AppColors.fieldBorder(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: username.isEmpty
                            ? null
                            : () => _shareProfile(context, username),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText(context),
                          side: BorderSide(color: AppColors.fieldBorder(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Share Profile',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SegmentedTabBar(
                labels: const ['My Posts', 'Memories', 'Badges'],
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
              const SizedBox(height: 16),
              _TabContent(selectedTab: _selectedTab, username: username),
              const SizedBox(height: 24),
              _MenuTile(icon: Icons.bookmark_outline, label: 'Saved Places', onTap: () {}),
              _MenuTile(icon: Icons.notifications_none, label: 'Notifications', onTap: () {}),
              _MenuTile(icon: Icons.privacy_tip_outlined, label: 'Privacy', onTap: () {}),
              _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
              if (user?.isAdmin == true)
                _MenuTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin panel',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                    );
                  },
                ),
              _MenuTile(
                icon: Icons.logout,
                label: 'Log out',
                destructive: true,
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
              _MenuTile(
                icon: Icons.delete_forever_outlined,
                label: 'Delete account',
                destructive: true,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hisobni o\'chirish'),
        content: const Text(
          'Hisobingiz butunlay o\'chiriladi va uni tiklab bo\'lmaydi. '
          'Barcha shaxsiy ma\'lumotlaringiz o\'chiriladi. Davom etasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCB4B4B),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hisobni o\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _shareProfile(BuildContext context, String username) async {
    await Clipboard.setData(ClipboardData(text: 'mikka://profile/$username'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil havolasi nusxalandi')));
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
        );
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FriendsScreen()),
        );
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ShortsScreen()),
        );
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ConversationsScreen()),
        );
    }
  }
}

class _TabContent extends ConsumerWidget {
  const _TabContent({required this.selectedTab, required this.username});

  final int selectedTab;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (selectedTab) {
      case 0:
        return _PostsGrid(username: username);
      case 1:
        return const _MemoriesGrid();
      default:
        return _BadgesList(username: username);
    }
  }
}

class _PostsGrid extends ConsumerWidget {
  const _PostsGrid({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (username.isEmpty) return const SizedBox.shrink();
    final posts = ref.watch(postsByUsernameProvider(username));
    return posts.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyTabMessage(text: 'Hali postlar yo\'q');
        }
        return _ImageGrid(
          count: items.length,
          imageUrlAt: (i) => items[i].coverImageUrl,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyTabMessage(text: 'Postlarni yuklab bo\'lmadi'),
    );
  }
}

class _MemoriesGrid extends ConsumerWidget {
  const _MemoriesGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider);
    return memories.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyTabMessage(text: 'Eskirgan hikoyalar yo\'q');
        }
        return _ImageGrid(
          count: items.length,
          imageUrlAt: (i) => items[i].imageUrl,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyTabMessage(text: 'Xotiralarni yuklab bo\'lmadi'),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.count, required this.imageUrlAt});

  final int count;
  final String? Function(int index) imageUrlAt;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final url = imageUrlAt(index);
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
  }
}

class _BadgesList extends ConsumerWidget {
  const _BadgesList({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (username.isEmpty) return const SizedBox.shrink();
    final badges = ref.watch(badgesByUsernameProvider(username));
    return badges.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyTabMessage(text: 'Hali nishonlar yo\'q');
        }
        return Column(
          children: items.map((b) => _BadgeTile(badge: b)).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyTabMessage(text: 'Nishonlarni yuklab bo\'lmadi'),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

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
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
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

class _EmptyTabMessage extends StatelessWidget {
  const _EmptyTabMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
        ),
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
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFCB4B4B) : AppColors.darkText(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mutedText(context), size: 20),
          ],
        ),
      ),
    );
  }
}
