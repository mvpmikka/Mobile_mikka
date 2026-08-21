import 'post.dart';

/// Mirrors a single item from the backend's `GET /users/:username/reviews`
/// — reuses `PostPlace` (id/name) since the place reference shape is
/// identical to Post's.
class UserReview {
  const UserReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.place,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final PostPlace place;
  final DateTime createdAt;

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: json['id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      place: PostPlace.fromJson(json['place'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
