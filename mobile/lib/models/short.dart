import 'chat_profile.dart';
import 'post.dart';

/// Mirrors the backend's `ShortFeedItem` (`GET /shorts/feed`).
class Short {
  const Short({
    required this.id,
    required this.user,
    required this.caption,
    required this.place,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.likeCount,
    required this.isLikedByMe,
    required this.createdAt,
  });

  final String id;
  final ChatProfile user;
  final String? caption;
  final PostPlace? place;
  final String videoUrl;
  final String? thumbnailUrl;
  final int likeCount;
  final bool isLikedByMe;
  final DateTime createdAt;

  Short copyWith({int? likeCount, bool? isLikedByMe}) {
    return Short(
      id: id,
      user: user,
      caption: caption,
      place: place,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt,
    );
  }

  factory Short.fromJson(Map<String, dynamic> json) {
    return Short(
      id: json['id'] as String,
      user: ChatProfile.fromJson(json['user'] as Map<String, dynamic>),
      caption: json['caption'] as String?,
      place: json['place'] == null
          ? null
          : PostPlace.fromJson(json['place'] as Map<String, dynamic>),
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      likeCount: json['likeCount'] as int,
      isLikedByMe: json['isLikedByMe'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
