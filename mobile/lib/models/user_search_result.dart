/// Mirrors the backend's `UserSearchResult` (GET /users/search).
class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName ?? username;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
