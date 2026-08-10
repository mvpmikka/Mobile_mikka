import 'user.dart';

/// Mirrors the backend's `AdminUserView` (`GET /admin/users`).
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isBanned,
    required this.isEmailVerified,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final UserRole role;
  final bool isBanned;
  final bool isEmailVerified;
  final DateTime createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      role: UserRole.fromJson(json['role'] as String? ?? 'USER'),
      isBanned: json['isBanned'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminUserPage {
  const AdminUserPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<AdminUser> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory AdminUserPage.fromJson(Map<String, dynamic> json) {
    return AdminUserPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}
