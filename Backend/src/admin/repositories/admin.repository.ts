import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '../../../generated/prisma/client';
import type { AdminStats } from '../types/admin-stats.type';
import type {
  CategoryBreakdown,
  DailyCheckInCount,
  TopPlace,
} from '../types/dashboard.type';
import type {
  MonthlyUserGrowth,
  RegionPlaceBreakdown,
} from '../types/super-admin-dashboard.type';

@Injectable()
export class AdminRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getStats(): Promise<AdminStats> {
    const [totalUsers, totalPlaces, totalReviews, totalCheckIns] =
      await Promise.all([
        this.prisma.user.count({ where: { deletedAt: null } }),
        this.prisma.place.count({ where: { deletedAt: null } }),
        this.prisma.review.count({ where: { deletedAt: null } }),
        this.prisma.checkIn.count({ where: { deletedAt: null } }),
      ]);
    return { totalUsers, totalPlaces, totalReviews, totalCheckIns };
  }

  // Joins across CheckIn -> Place -> PlaceCategory, which Prisma's groupBy
  // can't express (it only groups on a single model's own columns) — raw
  // SQL is the only way to aggregate across the relation.
  getCheckInsByCategory(): Promise<CategoryBreakdown[]> {
    return this.prisma.$queryRaw<CategoryBreakdown[]>`
      SELECT pc.id AS "categoryId", pc.name AS "categoryName",
             COUNT(ci.id)::int AS "checkInCount"
      FROM check_ins ci
      JOIN places p ON p.id = ci."placeId"
      JOIN place_categories pc ON pc.id = p."categoryId"
      WHERE ci."deletedAt" IS NULL AND p."deletedAt" IS NULL
      GROUP BY pc.id, pc.name
      ORDER BY "checkInCount" DESC
    `;
  }

  getTopPlacesByCheckIns(limit: number): Promise<TopPlace[]> {
    return this.prisma.$queryRaw<TopPlace[]>`
      SELECT p.id AS "placeId", p.name AS "placeName",
             COUNT(ci.id)::int AS "checkInCount"
      FROM check_ins ci
      JOIN places p ON p.id = ci."placeId"
      WHERE ci."deletedAt" IS NULL AND p."deletedAt" IS NULL
      GROUP BY p.id, p.name
      ORDER BY "checkInCount" DESC
      LIMIT ${limit}
    `;
  }

  // Only returns rows for days that had at least one check-in — the
  // service layer fills the zero-count gaps so the chart gets a
  // contiguous series.
  getDailyCheckInCounts(days: number): Promise<DailyCheckInCount[]> {
    return this.prisma.$queryRaw<DailyCheckInCount[]>`
      SELECT to_char(date_trunc('day', ci."createdAt"), 'YYYY-MM-DD') AS "date",
             COUNT(*)::int AS "count"
      FROM check_ins ci
      WHERE ci."deletedAt" IS NULL
        AND ci."createdAt" >= NOW() - (${days}::text || ' days')::interval
      GROUP BY 1
      ORDER BY 1
    `;
  }

  async getRoleAndModerationCounts(): Promise<{
    totalAdmins: number;
    totalSuperAdmins: number;
    bannedUsers: number;
    totalConversations: number;
    totalMessages: number;
  }> {
    const [
      totalAdmins,
      totalSuperAdmins,
      bannedUsers,
      totalConversations,
      totalMessages,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: Role.ADMIN, deletedAt: null } }),
      this.prisma.user.count({
        where: { role: Role.SUPER_ADMIN, deletedAt: null },
      }),
      this.prisma.user.count({ where: { isBanned: true, deletedAt: null } }),
      this.prisma.conversation.count(),
      this.prisma.message.count({ where: { deletedAt: null } }),
    ]);
    return {
      totalAdmins,
      totalSuperAdmins,
      bannedUsers,
      totalConversations,
      totalMessages,
    };
  }

  // Only returns rows for months that had at least one signup — the
  // service layer fills zero-count gaps, same reasoning as daily check-ins.
  getMonthlyUserGrowth(months: number): Promise<MonthlyUserGrowth[]> {
    return this.prisma.$queryRaw<MonthlyUserGrowth[]>`
      SELECT to_char(date_trunc('month', u."createdAt"), 'YYYY-MM') AS "month",
             COUNT(*)::int AS "newUsers"
      FROM users u
      WHERE u."deletedAt" IS NULL
        AND u."createdAt" >= date_trunc('month', NOW() - (${months - 1}::text || ' months')::interval)
      GROUP BY 1
      ORDER BY 1
    `;
  }

  getPlacesByRegion(): Promise<RegionPlaceBreakdown[]> {
    return this.prisma.$queryRaw<RegionPlaceBreakdown[]>`
      SELECT r.id AS "regionId", r.name AS "regionName",
             COUNT(p.id)::int AS "placeCount"
      FROM regions r
      LEFT JOIN places p ON p."regionId" = r.id AND p."deletedAt" IS NULL
      GROUP BY r.id, r.name
      ORDER BY "placeCount" DESC
    `;
  }
}
