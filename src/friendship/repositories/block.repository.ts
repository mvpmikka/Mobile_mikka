import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { BlockedUserItem } from '../types/friendship.type';

const profileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

@Injectable()
export class BlockRepository {
  constructor(private readonly prisma: PrismaService) {}

  async existsEitherDirection(
    userAId: string,
    userBId: string,
  ): Promise<boolean> {
    const row = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: userAId, blockedId: userBId },
          { blockerId: userBId, blockedId: userAId },
        ],
      },
      select: { id: true },
    });
    return row !== null;
  }

  // Directional — distinct from existsEitherDirection: B having already
  // blocked A doesn't stop A from separately blocking B (each direction is
  // its own row/unique key), it just means A can't create the same
  // (blockerId, blockedId) row twice.
  async existsDirectional(
    blockerId: string,
    blockedId: string,
  ): Promise<boolean> {
    const row = await this.prisma.block.findUnique({
      where: { blockerId_blockedId: { blockerId, blockedId } },
      select: { id: true },
    });
    return row !== null;
  }

  // Blocking tears down any existing relationship in the same transaction:
  // the Friendship pair (both directions) and any pending FriendRequest
  // (either direction) between the two users. See Block model's comment —
  // this is the full extent of what blocking does in V1.
  async blockAndCleanup(blockerId: string, blockedId: string): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.block.create({
        data: { blocker: { connect: { id: blockerId } }, blocked: { connect: { id: blockedId } } },
      }),
      this.prisma.friendship.deleteMany({
        where: {
          OR: [
            { userId: blockerId, friendId: blockedId },
            { userId: blockedId, friendId: blockerId },
          ],
        },
      }),
      this.prisma.friendRequest.deleteMany({
        where: {
          OR: [
            { requesterId: blockerId, addresseeId: blockedId },
            { requesterId: blockedId, addresseeId: blockerId },
          ],
        },
      }),
    ]);
  }

  async unblock(blockerId: string, blockedId: string): Promise<boolean> {
    const result = await this.prisma.block.deleteMany({
      where: { blockerId, blockedId },
    });
    return result.count > 0;
  }

  async findManyByBlocker(
    blockerId: string,
    page: number,
    limit: number,
  ): Promise<{ items: BlockedUserItem[]; total: number }> {
    const where = { blockerId };
    const [rows, total] = await Promise.all([
      this.prisma.block.findMany({
        where,
        include: { blocked: { select: profileSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.block.count({ where }),
    ]);

    const items: BlockedUserItem[] = rows.map((row) => ({
      ...row.blocked,
      blockedAt: row.createdAt,
    }));
    return { items, total };
  }

  async userExists(id: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id, deletedAt: null },
      select: { id: true },
    });
    return user !== null;
  }
}