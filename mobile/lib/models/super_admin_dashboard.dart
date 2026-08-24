class MonthlyUserGrowth {
  const MonthlyUserGrowth({required this.month, required this.newUsers});

  /// "YYYY-MM"
  final String month;
  final int newUsers;

  factory MonthlyUserGrowth.fromJson(Map<String, dynamic> json) {
    return MonthlyUserGrowth(
      month: json['month'] as String,
      newUsers: json['newUsers'] as int,
    );
  }
}

class RegionPlaceBreakdown {
  const RegionPlaceBreakdown({
    required this.regionId,
    required this.regionName,
    required this.placeCount,
  });

  final String regionId;
  final String regionName;
  final int placeCount;

  factory RegionPlaceBreakdown.fromJson(Map<String, dynamic> json) {
    return RegionPlaceBreakdown(
      regionId: json['regionId'] as String,
      regionName: json['regionName'] as String,
      placeCount: json['placeCount'] as int,
    );
  }
}

/// Mirrors the backend's `SuperAdminDashboard` (`GET /admin/super-dashboard`).
class SuperAdminDashboard {
  const SuperAdminDashboard({
    required this.totalAdmins,
    required this.totalSuperAdmins,
    required this.bannedUsers,
    required this.totalConversations,
    required this.totalMessages,
    required this.userGrowthLast6Months,
    required this.placesByRegion,
  });

  final int totalAdmins;
  final int totalSuperAdmins;
  final int bannedUsers;
  final int totalConversations;
  final int totalMessages;
  final List<MonthlyUserGrowth> userGrowthLast6Months;
  final List<RegionPlaceBreakdown> placesByRegion;

  factory SuperAdminDashboard.fromJson(Map<String, dynamic> json) {
    return SuperAdminDashboard(
      totalAdmins: json['totalAdmins'] as int,
      totalSuperAdmins: json['totalSuperAdmins'] as int,
      bannedUsers: json['bannedUsers'] as int,
      totalConversations: json['totalConversations'] as int,
      totalMessages: json['totalMessages'] as int,
      userGrowthLast6Months: (json['userGrowthLast6Months'] as List<dynamic>)
          .map((e) => MonthlyUserGrowth.fromJson(e as Map<String, dynamic>))
          .toList(),
      placesByRegion: (json['placesByRegion'] as List<dynamic>)
          .map((e) => RegionPlaceBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
