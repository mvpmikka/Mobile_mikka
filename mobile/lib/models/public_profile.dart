/// Mirrors the backend's `PublicProfile` (`GET /users/:username`) — another
/// user's profile as seen by the current viewer (or anonymously).
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.bio,
    required this.avatarUrl,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowedByMe,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final bool isFollowedByMe;

  String get displayName => fullName ?? username;

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      followersCount: json['followersCount'] as int,
      followingCount: json['followingCount'] as int,
      isFollowedByMe: json['isFollowedByMe'] as bool,
    );
  }
}
