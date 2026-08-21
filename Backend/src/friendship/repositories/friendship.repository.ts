import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { FriendItem, LatestCheckInItem } from '../types/friendship.type';

const profileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

@Injectable()
export class FriendshipRepository {
  constructor(private readonly prisma: PrismaService) {}

  async exists(userId: string, friendId: string): Promise<boolean> {
    const row = await this.prisma.friendship.findUnique({
      where: { userId_friendId: { userId, friendId } },
      select: { id: true },
    });
    return row !== null;
  }

  async findManyByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: FriendItem[]; total: number }> {
    const where = { userId };
    const [rows, total] = await Promise.all([
      this.prisma.friendship.findMany({
        where,
        include: { friend: { select: profileSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.friendship.count({ where }),
    ]);

    const items: FriendItem[] = rows.map((row) => ({
      ...row.friend,
      friendsSince: row.createdAt,
    }));
    return { items, total };
  }

  // Unpaginated, ids only — for internal orchestration (e.g. Story's feed
  // building a WHERE userId IN (...friend ids) query), never returned
  // directly from a controller. A friend *count* is bounded (hundreds at
  // most), unlike the user base as a whole, so unpaginated is fine here.
  async findAllFriendIds(userId: string): Promise<string[]> {
    const rows = await this.prisma.friendship.findMany({
      where: { userId },
      select: { friendId: true },
    });
    return rows.map((row) => row.friendId);
  }

  // Each user's single most recent active check-in, batched for a list of
  // users — `distinct` + `orderBy` on the same field is Prisma-native here
  // (unlike the "distinct on a related model's field" case used
  // elsewhere in this codebase), so no application-side dedup is needed.
  // Reads the check_ins table directly (see LatestCheckInItem's comment)
  // rather than importing CheckInModule, to avoid a module import cycle:
  // CheckInModule -> PrivacyModule -> FriendshipModule.
  async findLatestCheckIns(userIds: string[]): Promise<LatestCheckInItem[]> {
    if (userIds.length === 0) {
      return [];
    }
    const rows = await this.prisma.checkIn.findMany({
      where: { userId: { in: userIds }, deletedAt: null },
      include: {
        place: { select: { name: true, latitude: true, longitude: true } },
      },
      orderBy: { createdAt: 'desc' },
      distinct: ['userId'],
    });
    return rows.map((row) => ({
      userId: row.userId,
      placeName: row.place.name,
      latitude: row.place.latitude,
      longitude: row.place.longitude,
      createdAt: row.createdAt,
    }));
  }

  // Both directions are deleted as one statement (single DELETE ... WHERE
  // OR, not two round trips) — either both rows go or neither does.
  // Returns false if the pair didn't exist so the service can 404.
  async deletePair(userId: string, friendId: string): Promise<boolean> {
    const result = await this.prisma.friendship.deleteMany({
      where: {
        OR: [
          { userId, friendId },
          { userId: friendId, friendId: userId },
        ],
      },
    });
    return result.count > 0;
  }
}
