import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { Prisma, Review } from '../../../generated/prisma/client';

const reviewerSelect = {
  id: true,
  username: true,
  fullName: true,
} as const;

@Injectable()
export class ReviewRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Review | null> {
    return this.prisma.review.findUnique({ where: { id, deletedAt: null } });
  }

  findByUserAndPlace(userId: string, placeId: string): Promise<Review | null> {
    return this.prisma.review.findFirst({
      where: { userId, placeId, deletedAt: null },
    });
  }

  async findManyByPlace(placeId: string, page: number, limit: number) {
    const where: Prisma.ReviewWhereInput = { placeId, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        include: { user: { select: reviewerSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.review.count({ where }),
    ]);
    return { items, total };
  }

  // Reviews have no privacy gating anywhere in this codebase — they're
  // already shown unguarded on a place's public review list
  // (findManyByPlace/GET places/:placeId/reviews), so a user's own review
  // history is exposed the same way, unlike CheckIn/Story which do gate
  // on PrivacySettings.
  async findManyByUser(userId: string, page: number, limit: number) {
    const where: Prisma.ReviewWhereInput = { userId, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        include: { place: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.review.count({ where }),
    ]);
    return { items, total };
  }

  // Read-only against `users` — kept minimal and local to this module
  // rather than importing UserModule/UserService, per CLAUDE.md's
  // module-independence principle (same approach CheckIn uses).
  async findUserIdByUsername(username: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({
      where: { username, deletedAt: null },
      select: { id: true },
    });
    return user?.id ?? null;
  }

  create(data: Prisma.ReviewCreateInput) {
    return this.prisma.review.create({
      data,
      include: { user: { select: reviewerSelect } },
    });
  }

  update(id: string, data: Prisma.ReviewUpdateInput) {
    return this.prisma.review.update({
      where: { id },
      data,
      include: { user: { select: reviewerSelect } },
    });
  }

  softDelete(id: string): Promise<Review> {
    return this.prisma.review.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  reply(id: string, reply: string): Promise<Review> {
    return this.prisma.review.update({
      where: { id },
      data: { ownerReply: reply, ownerRepliedAt: new Date() },
      include: { user: { select: reviewerSelect } },
    });
  }

  // 1..5 -> count of reviews at that rating for the place, used to render
  // the rating-breakdown bars — maintained on read (no trigger/denorm,
  // unlike PlaceRatingSummary — a groupBy is cheap enough for this).
  async getRatingBreakdown(placeId: string): Promise<Record<number, number>> {
    const rows = await this.prisma.review.groupBy({
      by: ['rating'],
      where: { placeId, deletedAt: null },
      _count: true,
    });
    const breakdown: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    for (const row of rows) {
      breakdown[row.rating] = row._count;
    }
    return breakdown;
  }

  // Read-only existence check against `places` — kept minimal and local to
  // this module rather than importing PlaceModule/PlaceService, per
  // CLAUDE.md's module-independence principle (same approach Search uses).
  async placeExists(placeId: string): Promise<boolean> {
    const place = await this.prisma.place.findUnique({
      where: { id: placeId, deletedAt: null },
      select: { id: true },
    });
    return place !== null;
  }
}
