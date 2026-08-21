import 'chat_profile.dart';

/// Mirrors the backend's `FriendItem` (`GET /users/me/friends`).
class Friend {
  const Friend({required this.profile, required this.friendsSince});

  final ChatProfile profile;
  final DateTime friendsSince;

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      profile: ChatProfile.fromJson(json),
      friendsSince: DateTime.parse(json['friendsSince'] as String),
    );
  }

  // Backend `FollowItem` has the same profile shape as `FriendItem`, just
  // with `followedAt` instead of `friendsSince` — reused here (as
  // `friendsSince`, read loosely as "since" for either relationship)
  // rather than adding a near-duplicate model for followers/following.
  factory Friend.fromFollowJson(Map<String, dynamic> json) {
    return Friend(
      profile: ChatProfile.fromJson(json),
      friendsSince: DateTime.parse(json['followedAt'] as String),
    );
  }
}
