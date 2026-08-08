/// Mirrors the backend's `PrivateProfile` shape (`GET /users/me`).
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.profileCompleted,
    required this.createdAt,
  });

  final String id;
  final String email;
  final bool isEmailVerified;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool profileCompleted;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      isEmailVerified: json['isEmailVerified'] as bool,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      profileCompleted: json['profileCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
