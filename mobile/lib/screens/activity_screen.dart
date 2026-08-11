import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'explore_screen.dart';
import 'friends_screen.dart';
import 'nearby_places_screen.dart';
import 'profile_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _selectedNavIndex = 3;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.orange,
                onRefresh: () => ref.refresh(notificationsProvider.future),
                child: notificationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                  error: (error, _) => _ActivityMessage(
                    text: 'Faoliyatni yuklab bo\'lmadi',
                    onRetry: () => ref.invalidate(notificationsProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const _ActivityMessage(
                        text: 'Hozircha faoliyat yo\'q',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _NotificationTile(
                          item: item,
                          onTap: item.isUnread
                              ? () => _markRead(item)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
        onAddTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NearbyPlacesScreen()),
          );
        },
      ),
    );
  }

  Future<void> _markRead(NotificationItem item) async {
    try {
      await ref.read(notificationServiceProvider).markRead(item.id);
      ref.invalidate(notificationsProvider);
    } catch (_) {
      // Marking as read is best-effort — a failed request just leaves the
      // item showing as unread, which is harmless.
    }
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
      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
    }
  }
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text(
                      'Qayta urinish',
                      style: TextStyle(color: AppColors.orange),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, this.onTap});

  final NotificationItem item;
  final VoidCallback? onTap;

  IconData get _icon {
    switch (item.type) {
      case NotificationType.friendRequest:
        return Icons.person_add_alt_1;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.storyUpdate:
        return Icons.camera_alt_outlined;
      case NotificationType.unknown:
        return Icons.notifications_none;
    }
  }

  String get _relativeTime {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${item.createdAt.day}.${item.createdAt.month}.${item.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.isUnread
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: 20,
                color: item.isUnread ? AppColors.orange : AppColors.mutedText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkText,
                      fontWeight: item.isUnread
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
