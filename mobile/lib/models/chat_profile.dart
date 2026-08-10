/// Mirrors the backend's `ChatProfileSummary` / `FriendProfileSummary`.
class ChatProfile {
  const ChatProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName ?? username ?? 'Foydalanuvchi';

  factory ChatProfile.fromJson(Map<String, dynamic> json) {
    return ChatProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
