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
}
