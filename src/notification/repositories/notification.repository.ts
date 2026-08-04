import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  Notification,
  NotificationType,
  Prisma,
} from '../../../generated/prisma/client';

export interface MinimalUserProfile {
  id: string;
  username: string | null;
}

@Injectable()
export class NotificationRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(
    userId: string,
    type: NotificationType,
    body: string,
    data?: Record<string, unknown>,
  ): Promise<Notification> {
    return this.prisma.notification.create({
      data: {
        user: { connect: { id: userId } },
        type,
        body,
        data: data as Prisma.InputJsonValue | undefined,
      },
    });
  }

  async findManyByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: Notification[]; total: number }> {
    const where = { userId };
    const [items, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
    ]);
    return { items, total };
  }

  countUnread(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, readAt: null },
    });
  }

  async markRead(id: string, userId: string): Promise<boolean> {
    const result = await this.prisma.notification.updateMany({
      where: { id, userId, readAt: null },
      data: { readAt: new Date() },
    });
    return result.count > 0;
  }

  async markAllRead(userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
  }

  // Read-only against `users` — kept minimal and local to this module
  // rather than importing UserModule/UserService, per CLAUDE.md's
  // module-independence principle (same approach every other module's
  // local profile/existence check uses). Listeners use this to render a
  // notification body (e.g. the requester's username) from just an id.
  findUserProfile(id: string): Promise<MinimalUserProfile | null> {
    return this.prisma.user.findUnique({
      where: { id, deletedAt: null },
      select: { id: true, username: true },
    });
  }
}