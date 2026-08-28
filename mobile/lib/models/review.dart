import 'post.dart';

class ReviewAuthor {
  const ReviewAuthor({required this.id, required this.username, required this.fullName});

  final String id;
  final String username;
  final String? fullName;

  factory ReviewAuthor.fromJson(Map<String, dynamic> json) {
    return ReviewAuthor(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
    );
  }
}

/// Mirrors a single item from the backend's `GET /places/:placeId/reviews`
/// (the place-owner/admin view — includes [ownerReply]).
class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.ownerReply,
    required this.ownerRepliedAt,
    required this.user,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? ownerReply;
  final DateTime? ownerRepliedAt;
  final ReviewAuthor user;
  final DateTime createdAt;

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      id: json['id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      ownerReply: json['ownerReply'] as String?,
      ownerRepliedAt: json['ownerRepliedAt'] != null
          ? DateTime.parse(json['ownerRepliedAt'] as String)
          : null,
      user: ReviewAuthor.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PlaceReviewPage {
  const PlaceReviewPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PlaceReview> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory PlaceReviewPage.fromJson(Map<String, dynamic> json) {
    return PlaceReviewPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}

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
