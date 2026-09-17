import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/notification_item.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        title: Text(
          'Bildirishnomalar',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text(
              'Hammasini o\'qish',
              style: TextStyle(color: AppColors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificationsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.orange)),
          error: (e, _) => _CenteredMessage(
            text: e is ApiException ? e.message : 'Yuklab bo\'lmadi',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _CenteredMessage(text: 'Hali bildirishnoma yo\'q');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _NotificationTile(item: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  IconData get _icon {
    switch (item.type) {
      case NotificationType.friendRequest:
        return Icons.person_add_alt_1;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.missedCall:
        return Icons.call_missed;
      case NotificationType.follow:
        return Icons.favorite_border;
      case NotificationType.badgeEarned:
        return Icons.emoji_events_outlined;
      case NotificationType.unknown:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: item.isUnread
          ? () async {
              await ref.read(notificationServiceProvider).markRead(item.id);
              ref.invalidate(notificationsProvider);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isUnread
              ? AppColors.orange.withValues(alpha: 0.06)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Row(
          children: [
            Icon(_icon, color: AppColors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.body,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.darkText(context),
                ),
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
