/// Mirrors the backend's `AdminStats` (`GET /admin/stats`).
class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.totalPlaces,
    required this.totalReviews,
    required this.totalCheckIns,
  });

  final int totalUsers;
  final int totalPlaces;
  final int totalReviews;
  final int totalCheckIns;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] as int,
      totalPlaces: json['totalPlaces'] as int,
      totalReviews: json['totalReviews'] as int,
      totalCheckIns: json['totalCheckIns'] as int,
    );
  }
}
