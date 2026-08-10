import 'chat_message.dart';
import 'chat_profile.dart';

class MessagePreview {
  const MessagePreview({
    required this.id,
    required this.sender,
    required this.text,
    required this.imageUrl,
    required this.place,
    required this.createdAt,
  });

  final String id;
  final ChatProfile sender;
  final String? text;
  final String? imageUrl;
  final MessagePlace? place;
  final DateTime createdAt;

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      id: json['id'] as String,
      sender: ChatProfile.fromJson(json['sender'] as Map<String, dynamic>),
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      place: json['place'] != null
          ? MessagePlace.fromJson(json['place'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Short line shown under the conversation name in the chats list.
  String get summary {
    if (text != null && text!.isNotEmpty) return text!;
    if (imageUrl != null) return '📷 Rasm';
    if (place != null) return '📍 ${place!.name}';
    return '';
  }
}

/// Mirrors the backend's `ConversationListItem` (`GET /conversations`).
class ConversationListItem {
  const ConversationListItem({
    required this.id,
    required this.type,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String? name;
  final List<ChatProfile> participants;
  final MessagePreview? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  bool get isPrivate => type == 'PRIVATE';

  /// The other participant in a PRIVATE conversation — null for GROUP,
  /// where [name] should be used instead.
  ChatProfile? otherParticipant(String myUserId) {
    if (!isPrivate) return null;
    for (final participant in participants) {
      if (participant.id != myUserId) return participant;
    }
    return null;
  }

  String displayName(String myUserId) {
    if (!isPrivate) return name ?? 'Guruh';
    return otherParticipant(myUserId)?.displayName ?? 'Foydalanuvchi';
  }

  factory ConversationListItem.fromJson(Map<String, dynamic> json) {
    return ConversationListItem(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => ChatProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? MessagePreview.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Mirrors the backend's `ConversationDetail` (`POST/GET /conversations/:id`).
class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.type,
    required this.name,
    required this.createdById,
    required this.participants,
  });

  final String id;
  final String type;
  final String? name;
  final String createdById;
  final List<ChatProfile> participants;

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    return ConversationDetail(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      createdById: json['createdById'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => ChatProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
