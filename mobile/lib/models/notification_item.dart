enum NotificationType { friendRequest, newMessage, storyUpdate, unknown }

NotificationType _typeFromJson(String raw) {
  switch (raw) {
    case 'FRIEND_REQUEST':
      return NotificationType.friendRequest;
    case 'NEW_MESSAGE':
      return NotificationType.newMessage;
    case 'STORY_UPDATE':
      return NotificationType.storyUpdate;
    default:
      return NotificationType.unknown;
  }
}

/// Mirrors the backend's `NotificationItem` (GET /notifications). `body` is
/// already formatted human-readable text produced server-side by the
/// listener that created the notification (e.g. friend-request.listener.ts).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: _typeFromJson(json['type'] as String),
      body: json['body'] as String,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
