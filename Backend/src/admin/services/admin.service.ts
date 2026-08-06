import { Injectable } from '@nestjs/common';
import { AdminRepository } from '../repositories/admin.repository';
import { UserService } from '../../user/user.service';
import type { PaginatedResult } from '../../user/user.service';
import { TokenService } from '../../auth/services/token.service';
import type { AdminStats } from '../types/admin-stats.type';
import type { AdminUserView } from '../../user/types/admin-user.type';
import type {
  AdminDashboard,
  DailyCheckInCount,
} from '../types/dashboard.type';
import type {
  MonthlyUserGrowth,
  SuperAdminDashboard,
} from '../types/super-admin-dashboard.type';

const DASHBOARD_TOP_PLACES_LIMIT = 5;
const DASHBOARD_CHECK_IN_DAYS = 14;
const DASHBOARD_GROWTH_MONTHS = 6;

@Injectable()
export class AdminService {
  constructor(
    private readonly adminRepository: AdminRepository,
    private readonly userService: UserService,
    private readonly tokenService: TokenService,
  ) {}

  getStats(): Promise<AdminStats> {
    return this.adminRepository.getStats();
  }

  // Operational dashboard for ADMIN (and SUPER_ADMIN, which is a superset
  // of ADMIN) — see docs on AdminDashboard/SuperAdminDashboard for why the
  // split is where it is.
  async getDashboard(): Promise<AdminDashboard> {
    const [totals, checkInsByCategory, topPlaces, dailyCounts] =
      await Promise.all([
        this.adminRepository.getStats(),
        this.adminRepository.getCheckInsByCategory(),
        this.adminRepository.getTopPlacesByCheckIns(DASHBOARD_TOP_PLACES_LIMIT),
        this.adminRepository.getDailyCheckInCounts(DASHBOARD_CHECK_IN_DAYS),
      ]);

    return {
      totals,
      checkInsByCategory,
      topPlaces,
      checkInsLast14Days: fillDailyGaps(dailyCounts, DASHBOARD_CHECK_IN_DAYS),
    };
  }

  async getSuperDashboard(): Promise<SuperAdminDashboard> {
    const [roleCounts, monthlyGrowth, placesByRegion] = await Promise.all([
      this.adminRepository.getRoleAndModerationCounts(),
      this.adminRepository.getMonthlyUserGrowth(DASHBOARD_GROWTH_MONTHS),
      this.adminRepository.getPlacesByRegion(),
    ]);

    return {
      ...roleCounts,
      userGrowthLast6Months: fillMonthlyGaps(
        monthlyGrowth,
        DASHBOARD_GROWTH_MONTHS,
      ),
      placesByRegion,
    };
  }

  listUsers(
    page: number,
    limit: number,
    search?: string,
  ): Promise<PaginatedResult<AdminUserView>> {
    return this.userService.listForAdmin(page, limit, search);
  }

  getUser(id: string): Promise<AdminUserView> {
    return this.userService.getForAdmin(id);
  }

  // Ban is a User-domain state change (UserService.ban, including the
  // "can't ban yourself" rule) plus an immediate session kill — revoking
  // every refresh token so the ban takes effect now, not whenever the
  // user's existing session would have naturally expired. The reach into
  // Auth's TokenService belongs here, not in UserService, since User has
  // no business knowing about refresh tokens — see docs/foundation.md.
  async banUser(id: string, requestedByUserId: string): Promise<AdminUserView> {
    const user = await this.userService.ban(id, requestedByUserId);
    await this.tokenService.revokeAllForUser(id);
    return user;
  }

  unbanUser(id: string): Promise<void> {
    return this.userService.unban(id);
  }
}

// The repository only returns days/months that had activity — a chart
// needs a contiguous series, so the zero-count gaps are filled here rather
// than pushing that concern into the raw SQL.
function fillDailyGaps(
  rows: DailyCheckInCount[],
  days: number,
): DailyCheckInCount[] {
  const countsByDate = new Map(rows.map((row) => [row.date, row.count]));
  const result: DailyCheckInCount[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setUTCDate(date.getUTCDate() - i);
    const key = date.toISOString().slice(0, 10);
    result.push({ date: key, count: countsByDate.get(key) ?? 0 });
  }
  return result;
}

function fillMonthlyGaps(
  rows: MonthlyUserGrowth[],
  months: number,
): MonthlyUserGrowth[] {
  const countsByMonth = new Map(rows.map((row) => [row.month, row.newUsers]));
  const result: MonthlyUserGrowth[] = [];
  for (let i = months - 1; i >= 0; i--) {
    const date = new Date();
    date.setUTCDate(1);
    date.setUTCMonth(date.getUTCMonth() - i);
    const key = date.toISOString().slice(0, 7);
    result.push({ month: key, newUsers: countsByMonth.get(key) ?? 0 });
  }
  return result;
}
