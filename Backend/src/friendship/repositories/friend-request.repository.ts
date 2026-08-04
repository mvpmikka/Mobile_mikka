import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { FriendRequest } from '../../../generated/prisma/client';
import type { FriendRequestItem } from '../types/friendship.type';

const profileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

@Injectable()
export class FriendRequestRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<FriendRequest | null> {
    return this.prisma.friendRequest.findUnique({ where: { id } });
  }

  findPending(
    requesterId: string,
    addresseeId: string,
  ): Promise<FriendRequest | null> {
    return this.prisma.friendRequest.findUnique({
      where: { requesterId_addresseeId: { requesterId, addresseeId } },
    });
  }

  create(requesterId: string, addresseeId: string): Promise<FriendRequest> {
    return this.prisma.friendRequest.create({
      data: {
        requester: { connect: { id: requesterId } },
        addressee: { connect: { id: addresseeId } },
      },
    });
  }

  delete(id: string): Promise<void> {
    return this.prisma.friendRequest
      .delete({ where: { id } })
      .then(() => undefined);
  }

  // Accepting is a FriendRequest lifecycle transition that also produces a
  // Friendship side effect — both happen atomically so no request is ever
  // lost without a resulting friendship, or vice versa.
  async acceptAndCreateFriendship(
    requestId: string,
    requesterId: string,
    addresseeId: string,
  ): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.friendRequest.delete({ where: { id: requestId } }),
      this.prisma.friendship.create({
        data: { userId: requesterId, friendId: addresseeId },
      }),
      this.prisma.friendship.create({
        data: { userId: addresseeId, friendId: requesterId },
      }),
    ]);
  }

  async findManyReceived(
    addresseeId: string,
    page: number,
    limit: number,
  ): Promise<{ items: FriendRequestItem[]; total: number }> {
    const where = { addresseeId };
    const [rows, total] = await Promise.all([
      this.prisma.friendRequest.findMany({
        where,
        include: { requester: { select: profileSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.friendRequest.count({ where }),
    ]);

    const items: FriendRequestItem[] = rows.map((row) => ({
      id: row.id,
      createdAt: row.createdAt,
      user: row.requester,
    }));
    return { items, total };
  }

  async findManySent(
    requesterId: string,
    page: number,
    limit: number,
  ): Promise<{ items: FriendRequestItem[]; total: number }> {
    const where = { requesterId };
    const [rows, total] = await Promise.all([
      this.prisma.friendRequest.findMany({
        where,
        include: { addressee: { select: profileSelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.friendRequest.count({ where }),
    ]);

    const items: FriendRequestItem[] = rows.map((row) => ({
      id: row.id,
      createdAt: row.createdAt,
      user: row.addressee,
    }));
    return { items, total };
  }

  // Local existence check against `users` — kept minimal here rather than
  // importing UserModule/UserService, per CLAUDE.md's module-independence
  // principle (same approach Review uses for `placeExists`).
  async userExists(id: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id, deletedAt: null },
      select: { id: true },
    });
    return user !== null;
  }
}