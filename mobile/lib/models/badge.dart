/// Mirrors the backend's `UserBadgeItem` (`GET /users/:username/badges`).
/// Shown as "Badges" on your own profile, "Titles" on someone else's — same
/// data, different tab label, per the redesign plan.
class UserBadge {
  const UserBadge({
    required this.code,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.earnedAt,
  });

  final String code;
  final String name;
  final String description;
  final String? iconUrl;
  final DateTime earnedAt;

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}
