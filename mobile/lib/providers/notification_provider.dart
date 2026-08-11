import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(apiClient: ref.watch(apiClientProvider));
});

/// First page of notifications, newest first — enough for the Activity
/// screen's simple list (no pagination UI yet).
final notificationsProvider = FutureProvider<List<NotificationItem>>((
  ref,
) async {
  final page = await ref
      .watch(notificationServiceProvider)
      .list(page: 1, limit: 50);
  return page.items;
});
