import type { Order, OrderItem } from '../../../generated/prisma/client';

export type OrderWithItems = Order & { items: OrderItem[] };

export interface OrderListResult {
  items: OrderWithItems[];
  total: number;
  page: number;
  limit: number;
}

export interface OrderStats {
  newCount: number;
  acceptedCount: number;
  preparingCount: number;
  readyCount: number;
  completedCount: number;
  cancelledCount: number;
}
