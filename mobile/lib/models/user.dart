enum UserRole {
  user,
  admin,
  superAdmin;

  static UserRole fromJson(String value) {
    switch (value) {
      case 'ADMIN':
        return UserRole.admin;
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }
}

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
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String email;
  final bool isEmailVerified;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool profileCompleted;
  final UserRole role;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      isEmailVerified: json['isEmailVerified'] as bool,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      profileCompleted: json['profileCompleted'] as bool,
      role: UserRole.fromJson(json['role'] as String? ?? 'USER'),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
