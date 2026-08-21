import 'chat_profile.dart';

class PostPlace {
  const PostPlace({required this.id, required this.name});

  final String id;
  final String name;

  factory PostPlace.fromJson(Map<String, dynamic> json) {
    return PostPlace(id: json['id'] as String, name: json['name'] as String);
  }
}

class PostImage {
  const PostImage({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.position,
  });

  final String id;
  final String url;
  final String? thumbnailUrl;
  final int position;

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      position: json['position'] as int,
    );
  }
}

/// Mirrors the backend's `PostFeedItem` (`GET /users/:username/posts`).
class Post {
  const Post({
    required this.id,
    required this.user,
    required this.caption,
    required this.place,
    required this.images,
    required this.createdAt,
  });

  final String id;
  final ChatProfile user;
  final String? caption;
  final PostPlace? place;
  final List<PostImage> images;
  final DateTime createdAt;

  String? get coverImageUrl => images.isEmpty ? null : images.first.url;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      user: ChatProfile.fromJson(json['user'] as Map<String, dynamic>),
      caption: json['caption'] as String?,
      place: json['place'] == null
          ? null
          : PostPlace.fromJson(json['place'] as Map<String, dynamic>),
      images: (json['images'] as List<dynamic>)
          .map((e) => PostImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Mirrors the backend's `MemoryItem` (`GET /users/me/memories`) — the
/// owner's own expired Stories, shown as an archive, not real Posts.
class Memory {
  const Memory({
    required this.id,
    required this.text,
    required this.imageUrl,
    required this.place,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String? text;
  final String? imageUrl;
  final PostPlace? place;
  final DateTime createdAt;
  final DateTime expiresAt;

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      place: json['place'] == null
          ? null
          : PostPlace.fromJson(json['place'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
