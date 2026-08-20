import { Injectable } from '@nestjs/common';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/client';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  BadgeCriteriaType,
  BadgeDefinition,
  UserBadge,
} from '../../../generated/prisma/client';
import type { UserBadgeItem } from '../types/badge.type';

@Injectable()
export class BadgeRepository {
  constructor(private readonly prisma: PrismaService) {}

  findDefinitionsByCriteriaTypes(
    criteriaTypes: BadgeCriteriaType[],
  ): Promise<BadgeDefinition[]> {
    return this.prisma.badgeDefinition.findMany({
      where: { criteriaType: { in: criteriaTypes } },
    });
  }

  async findEarnedDefinitionIds(
    userId: string,
    definitionIds: string[],
  ): Promise<Set<string>> {
    const rows = await this.prisma.userBadge.findMany({
      where: { userId, badgeDefinitionId: { in: definitionIds } },
      select: { badgeDefinitionId: true },
    });
    return new Set(rows.map((row) => row.badgeDefinitionId));
  }

  // Idempotent against the (userId, badgeDefinitionId) unique constraint —
  // returns null instead of throwing if two evaluations race (e.g. a
  // check-in and a review landing at nearly the same time both trigger
  // evaluateForUser), so the caller can simply skip emitting BADGE_EARNED
  // rather than handle an error.
  async award(
    userId: string,
    badgeDefinitionId: string,
  ): Promise<UserBadge | null> {
    try {
      return await this.prisma.userBadge.create({
        data: {
          user: { connect: { id: userId } },
          badgeDefinition: { connect: { id: badgeDefinitionId } },
        },
      });
    } catch (error) {
      if (
        error instanceof PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return null;
      }
      throw error;
    }
  }

  countCheckInsByCategorySlugs(
    userId: string,
    categorySlugs: string[],
  ): Promise<number> {
    return this.prisma.checkIn.count({
      where: {
        userId,
        deletedAt: null,
        place: { category: { slug: { in: categorySlugs } } },
      },
    });
  }

  // No distinct-on-relation support in Prisma for this shape, and a raw
  // join is overkill at V1's per-user check-in volume — fetch each
  // check-in's region and dedupe in application code instead.
  async countDistinctRegionsCheckedIn(userId: string): Promise<number> {
    const rows = await this.prisma.checkIn.findMany({
      where: { userId, deletedAt: null },
      select: { place: { select: { regionId: true } } },
    });
    const regionIds = new Set(
      rows
        .map((row) => row.place.regionId)
        .filter((regionId): regionId is string => regionId !== null),
    );
    return regionIds.size;
  }

  countReviews(userId: string): Promise<number> {
    return this.prisma.review.count({ where: { userId, deletedAt: null } });
  }

  async findManyByUserId(userId: string): Promise<UserBadgeItem[]> {
    const rows = await this.prisma.userBadge.findMany({
      where: { userId },
      include: { badgeDefinition: true },
      orderBy: { earnedAt: 'desc' },
    });
    return rows.map((row) => ({
      code: row.badgeDefinition.code,
      name: row.badgeDefinition.name,
      description: row.badgeDefinition.description,
      iconUrl: row.badgeDefinition.iconUrl,
      earnedAt: row.earnedAt,
    }));
  }

  findDefinitionById(id: string): Promise<BadgeDefinition | null> {
    return this.prisma.badgeDefinition.findUnique({ where: { id } });
  }

  // Read-only against `users` — kept minimal and local to this module
  // rather than importing UserModule, per CLAUDE.md's module-independence
  // principle (same approach Story/Notification's local profile lookups use).
  async findUserIdByUsername(username: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({
      where: { username, deletedAt: null },
      select: { id: true },
    });
    return user?.id ?? null;
  }
}
