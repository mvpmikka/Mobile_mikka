import type { Booking, Order, OrderItem } from '../../../generated/prisma/client';

export interface CustomerSummary {
  customerName: string;
  customerPhone: string;
  ordersCount: number;
  bookingsCount: number;
  totalSpent: number;
  lastActivityAt: Date;
  isBlocked: boolean;
}

export interface CustomerListResult {
  items: CustomerSummary[];
  total: number;
  page: number;
  limit: number;
}

export interface CustomerDetail extends CustomerSummary {
  recentOrders: (Order & { items: OrderItem[] })[];
  recentBookings: Booking[];
}
