import type { NotificationType } from '../../../generated/prisma/client';

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface NotificationItem {
  id: string;
  type: NotificationType;
  body: string;
  data: Record<string, unknown> | null;
  readAt: Date | null;
  createdAt: Date;
}