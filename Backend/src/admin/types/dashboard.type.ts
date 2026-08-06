import type { AdminStats } from './admin-stats.type';

export interface CategoryBreakdown {
  categoryId: string;
  categoryName: string;
  checkInCount: number;
}

export interface TopPlace {
  placeId: string;
  placeName: string;
  checkInCount: number;
}

export interface DailyCheckInCount {
  date: string;
  count: number;
}

// ADMIN-level dashboard — day-to-day operational view: what's happening on
// the platform right now (volumes, popular places, recent activity).
// Deliberately excludes anything about admin/role management, which is
// SUPER_ADMIN's concern — see SuperAdminDashboard.
export interface AdminDashboard {
  totals: AdminStats;
  checkInsByCategory: CategoryBreakdown[];
  topPlaces: TopPlace[];
  checkInsLast14Days: DailyCheckInCount[];
}
