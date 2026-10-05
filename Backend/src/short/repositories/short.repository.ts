import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { Prisma, Short } from '../../../generated/prisma/client';
import type { CreateShortDto } from '../dto/create-short.dto';
import type { ShortFeedItem } from '../types/short.type';

const shortInclude = {
  user: {
    select: { id: true, username: true, fullName: true, avatarUrl: true },
  },
  place: { select: { id: true, name: true } },
  _count: { select: { likes: true } },
} as const;

type ShortRow = Prisma.ShortGetPayload<{ include: typeof shortInclude }>;

function toFeedItem(row: ShortRow, likedShortIds: Set<string>): ShortFeedItem {
  return {
    id: row.id,
    user: row.user,
    caption: row.caption,
    place: row.place,
    visibility: row.visibility,
    videoUrl: row.videoUrl,
    thumbnailUrl: row.thumbnailUrl,
    likeCount: row._count.likes,
    isLikedByMe: likedShortIds.has(row.id),
    createdAt: row.createdAt,
  };
}

@Injectable()
export class ShortRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Short | null> {
    return this.prisma.short.findUnique({ where: { id, deletedAt: null } });
  }

  create(userId: string, dto: CreateShortDto): Promise<ShortFeedItem> {
    return this.prisma.short
      .create({
        data: {
          user: { connect: { id: userId } },
          caption: dto.caption,
          visibility: dto.visibility,
          videoUrl: dto.videoUrl,
          thumbnailUrl: dto.thumbnailUrl,
          ...(dto.placeId ? { place: { connect: { id: dto.placeId } } } : {}),
        },
        include: shortInclude,
      })
      .then((row) => toFeedItem(row, new Set()));
  }

  softDelete(id: string): Promise<Short> {
    return this.prisma.short.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // Cross-user feed (unlike Post's per-owner findManyByUser): visible rows
  // are PUBLIC to everyone, the viewer's own regardless of visibility, or
  // FRIENDS-visibility from one of the viewer's friends. An anonymous
  // viewer (empty friendIds, undefined viewerId) only ever matches PUBLIC.
  async findFeed(
    viewerId: string | undefined,
    friendIds: string[],
    page: number,
    limit: number,
  ): Promise<{ items: ShortFeedItem[]; total: number }> {
    const where: Prisma.ShortWhereInput = {
      deletedAt: null,
      OR: [
        { visibility: 'PUBLIC' },
        ...(viewerId ? [{ userId: viewerId }] : []),
        ...(friendIds.length
          ? [{ userId: { in: friendIds }, visibility: 'FRIENDS' as const }]
          : []),
      ],
    };
    const [rows, total] = await Promise.all([
      this.prisma.short.findMany({
        where,
        include: shortInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.short.count({ where }),
    ]);

    // Batched per page, not per row, to avoid an N+1 query.
    const likedShortIds = viewerId
      ? new Set(
          (
            await this.prisma.shortLike.findMany({
              where: { userId: viewerId, shortId: { in: rows.map((r) => r.id) } },
              select: { shortId: true },
            })
          ).map((like) => like.shortId),
        )
      : new Set<string>();

    return { items: rows.map((row) => toFeedItem(row, likedShortIds)), total };
  }

  // Upsert, not create — like() is idempotent by design (same convention as
  // SavedPlace.save), so a second like of the same short is a no-op rather
  // than a unique-constraint error the service would have to catch.
  async like(userId: string, shortId: string): Promise<void> {
    await this.prisma.shortLike.upsert({
      where: { userId_shortId: { userId, shortId } },
      create: {
        user: { connect: { id: userId } },
        short: { connect: { id: shortId } },
      },
      update: {},
    });
  }

  async unlike(userId: string, shortId: string): Promise<void> {
    await this.prisma.shortLike.deleteMany({ where: { userId, shortId } });
  }

  // Read-only against `places` — kept minimal and local to this module
  // rather than importing PlaceModule, per CLAUDE.md's module-independence
  // principle (same approach Post/Review/CheckIn use).
  async placeExists(placeId: string): Promise<boolean> {
    const place = await this.prisma.place.findUnique({
      where: { id: placeId, deletedAt: null },
      select: { id: true },
    });
    return place !== null;
  }
}
