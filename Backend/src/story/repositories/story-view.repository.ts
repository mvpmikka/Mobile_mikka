import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { StoryViewerItem } from '../types/story.type';

const viewerProfileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

@Injectable()
export class StoryViewRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Idempotent — a repeat "mark viewed" call is a no-op, same reasoning as
  // SavedPlace.save. The unique constraint on (storyId, viewerId) is what
  // makes this safe to upsert against instead of erroring on conflict.
  async markViewed(storyId: string, viewerId: string): Promise<void> {
    await this.prisma.storyView.upsert({
      where: { storyId_viewerId: { storyId, viewerId } },
      create: {
        story: { connect: { id: storyId } },
        viewer: { connect: { id: viewerId } },
      },
      update: {},
    });
  }

  async findViewedStoryIds(
    viewerId: string,
    storyIds: string[],
  ): Promise<string[]> {
    if (storyIds.length === 0) {
      return [];
    }
    const rows = await this.prisma.storyView.findMany({
      where: { viewerId, storyId: { in: storyIds } },
      select: { storyId: true },
    });
    return rows.map((row) => row.storyId);
  }

  async findManyByStory(
    storyId: string,
    page: number,
    limit: number,
  ): Promise<{ items: StoryViewerItem[]; total: number }> {
    const where = { storyId };
    const [rows, total] = await Promise.all([
      this.prisma.storyView.findMany({
        where,
        include: { viewer: { select: viewerProfileSelect } },
        orderBy: { viewedAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.storyView.count({ where }),
    ]);

    const items: StoryViewerItem[] = rows.map((row) => ({
      ...row.viewer,
      viewedAt: row.viewedAt,
    }));
    return { items, total };
  }
}