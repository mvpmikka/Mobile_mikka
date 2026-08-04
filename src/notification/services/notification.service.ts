import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationRepository } from '../repositories/notification.repository';
import { NotificationGateway } from '../notification.gateway';
import type { Notification, NotificationType } from '../../../generated/prisma/client';
import type { NotificationItem, PaginatedResult } from '../types/notification.type';

@Injectable()
export class NotificationService {
  constructor(
    private readonly notificationRepository: NotificationRepository,
    private readonly notificationGateway: NotificationGateway,
  ) {}

  // The one entry point every listener (friend-request/message/story) calls
  // — persists the notification, then pushes it over the WebSocket
  // gateway. Listeners never touch NotificationRepository or
  // NotificationGateway directly.
  async notify(
    userId: string,
    type: NotificationType,
    body: string,
    data?: Record<string, unknown>,
  ): Promise<void> {
    const notification = await this.notificationRepository.create(
      userId,
      type,
      body,
      data,
    );
    this.notificationGateway.push(userId, this.toItem(notification));
  }

  async list(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<NotificationItem>> {
    const { items, total } = await this.notificationRepository.findManyByUser(
      userId,
      page,
      limit,
    );
    return { items: items.map((item) => this.toItem(item)), total, page, limit };
  }

  async unreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.notificationRepository.countUnread(userId);
    return { count };
  }

  async markRead(id: string, userId: string): Promise<void> {
    const updated = await this.notificationRepository.markRead(id, userId);
    if (!updated) {
      throw new NotFoundException('Notification not found');
    }
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notificationRepository.markAllRead(userId);
  }

  private toItem(notification: Notification): NotificationItem {
    return {
      id: notification.id,
      type: notification.type,
      body: notification.body,
      data: (notification.data as Record<string, unknown> | null) ?? null,
      readAt: notification.readAt,
      createdAt: notification.createdAt,
    };
  }
}