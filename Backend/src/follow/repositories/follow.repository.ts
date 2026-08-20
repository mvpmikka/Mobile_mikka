import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { FollowItem } from '../types/follow.type';

const profileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

@Injectable()
export class FollowRepository {
  constructor(private readonly prisma: PrismaService) {}

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

  async existsDirectional(
    followerId: string,
    followingId: string,
  ): Promise<boolean> {
    const row = await this.prisma.follow.findUnique({
      where: { followerId_followingId: { followerId, followingId } },
      select: { id: true },
    });
    return row !== null;
  }

  async create(followerId: string, followingId: string): Promise<void> {
    await this.prisma.follow.create({
      data: {
        follower: { connect: { id: followerId } },
        following: { connect: { id: followingId } },
      },
    });
  }

  async remove(followerId: string, followingId: string): Promise<boolean> {
    const result = await this.prisma.follow.deleteMany({
      where: { followerId, followingId },
    });
    return result.count > 0;
  }

  countFollowers(userId: string): Promise<number> {
    return this.prisma.follow.count({ where: { followingId: userId } });
  }

  countFollowing(userId: string): Promise<number> {
    return this.prisma.follow.count({ where: { followerId: userId } });
  }

  async findManyFollowers(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: FollowItem[]; total: number }> {
    const where = { followingId: userId };
    const [rows, total] = await Promise.all([
      this.prisma.follow.findMany({
        where,
        include: { follower: { select: profileSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.follow.count({ where }),
    ]);
    const items: FollowItem[] = rows.map((row) => ({
      ...row.follower,
      followedAt: row.createdAt,
    }));
    return { items, total };
  }

  async findManyFollowing(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: FollowItem[]; total: number }> {
    const where = { followerId: userId };
    const [rows, total] = await Promise.all([
      this.prisma.follow.findMany({
        where,
        include: { following: { select: profileSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.follow.count({ where }),
    ]);
    const items: FollowItem[] = rows.map((row) => ({
      ...row.following,
      followedAt: row.createdAt,
    }));
    return { items, total };
  }
}
