import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { Prisma, Story } from '../../../generated/prisma/client';
import type { StoryFeedItem } from '../types/story.type';

const storyInclude = {
  user: { select: { id: true, username: true, fullName: true, avatarUrl: true } },
  place: { select: { id: true, name: true } },
} as const;

type StoryRow = Prisma.StoryGetPayload<{ include: typeof storyInclude }>;

function toFeedItem(row: StoryRow, viewedByMe: boolean): StoryFeedItem {
  return {
    id: row.id,
    user: row.user,
    text: row.text,
    imageUrl: row.imageUrl,
    place: row.place,
    createdAt: row.createdAt,
    expiresAt: row.expiresAt,
    viewedByMe,
  };
}

@Injectable()
export class StoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Story | null> {
    return this.prisma.story.findUnique({ where: { id, deletedAt: null } });
  }

  create(
    userId: string,
    data: { text?: string; imageUrl?: string; placeId?: string },
    expiresAt: Date,
  ): Promise<Story> {
    return this.prisma.story.create({
      data: {
        user: { connect: { id: userId } },
        text: data.text,
        imageUrl: data.imageUrl,
        ...(data.placeId ? { place: { connect: { id: data.placeId } } } : {}),
        expiresAt,
      },
    });
  }

  softDelete(id: string): Promise<Story> {
    return this.prisma.story.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // Active stories (not expired, not deleted) for one user — GET
  // /users/:username/stories. viewedByMe is filled in by the caller (needs
  // the viewer's identity, which this method doesn't take) — always false
  // here, overwritten by StoryService.
  async findManyByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: StoryFeedItem[]; total: number }> {
    const where: Prisma.StoryWhereInput = {
      userId,
      deletedAt: null,
      expiresAt: { gt: new Date() },
    };
    const [rows, total] = await Promise.all([
      this.prisma.story.findMany({
        where,
        include: storyInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.story.count({ where }),
    ]);
    return { items: rows.map((row) => toFeedItem(row, false)), total };
  }

  // Active stories from a specific set of owners (already resolved by
  // StoryService to "my friends who haven't set PRIVATE, plus me") — GET
  // /stories/feed.
  async findManyByUsers(
    userIds: string[],
    page: number,
    limit: number,
  ): Promise<{ items: StoryFeedItem[]; total: number }> {
    const where: Prisma.StoryWhereInput = {
      userId: { in: userIds },
      deletedAt: null,
      expiresAt: { gt: new Date() },
    };
    const [rows, total] = await Promise.all([
      this.prisma.story.findMany({
        where,
        include: storyInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.story.count({ where }),
    ]);
    return { items: rows.map((row) => toFeedItem(row, false)), total };
  }

  // Read-only against `places`/`users` — kept minimal and local to this
  // module rather than importing PlaceModule/UserModule, per CLAUDE.md's
  // module-independence principle (same approach Review/CheckIn use).
  async placeExists(placeId: string): Promise<boolean> {
    const place = await this.prisma.place.findUnique({
      where: { id: placeId, deletedAt: null },
      select: { id: true },
    });
    return place !== null;
  }

  async findUserIdByUsername(username: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({
      where: { username, deletedAt: null },
      select: { id: true },
    });
    return user?.id ?? null;
  }
}