export interface MonthlyUserGrowth {
  month: string;
  newUsers: number;
}

export interface RegionPlaceBreakdown {
  regionId: string;
  regionName: string;
  placeCount: number;
}

// SUPER_ADMIN-level dashboard — platform oversight: staffing (who holds
// elevated roles), moderation load (bans), growth trend, and geographic/
// system-wide spread. Everything here is either sensitive (role counts) or
// strategic (growth, regional spread) rather than day-to-day operational,
// which is what AdminDashboard covers instead.
export interface SuperAdminDashboard {
  totalAdmins: number;
  totalSuperAdmins: number;
  bannedUsers: number;
  totalConversations: number;
  totalMessages: number;
  userGrowthLast6Months: MonthlyUserGrowth[];
  placesByRegion: RegionPlaceBreakdown[];
}
