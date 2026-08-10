import 'chat_profile.dart';

class MessagePlace {
  const MessagePlace({required this.id, required this.name});

  final String id;
  final String name;

  factory MessagePlace.fromJson(Map<String, dynamic> json) {
    return MessagePlace(id: json['id'] as String, name: json['name'] as String);
  }
}

class ReplyPreview {
  const ReplyPreview({
    required this.id,
    required this.sender,
    required this.text,
    required this.imageUrl,
  });

  final String id;
  final ChatProfile sender;
  final String? text;
  final String? imageUrl;

  factory ReplyPreview.fromJson(Map<String, dynamic> json) {
    return ReplyPreview(
      id: json['id'] as String,
      sender: ChatProfile.fromJson(json['sender'] as Map<String, dynamic>),
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class MessageReaction {
  const MessageReaction({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });

  final String emoji;
  final int count;
  final bool reactedByMe;

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      count: json['count'] as int,
      reactedByMe: json['reactedByMe'] as bool,
    );
  }
}

/// Mirrors the backend's `MessageItem` (`GET/POST /conversations/:id/messages`,
/// and the `new_message` WebSocket event).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.imageUrl,
    required this.place,
    required this.replyTo,
    required this.reactions,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final ChatProfile sender;
  final String? text;
  final String? imageUrl;
  final MessagePlace? place;
  final ReplyPreview? replyTo;
  final List<MessageReaction> reactions;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      sender: ChatProfile.fromJson(json['sender'] as Map<String, dynamic>),
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      place: json['place'] != null
          ? MessagePlace.fromJson(json['place'] as Map<String, dynamic>)
          : null,
      replyTo: json['replyTo'] != null
          ? ReplyPreview.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
