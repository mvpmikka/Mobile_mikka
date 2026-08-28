import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { CustomerDetail, CustomerSummary } from '../types/customer.type';

const RECENT_TAKE = 50;

// Customers aren't a real table — Order/Booking.customerPhone are free
// text (no User link, see the Order/Booking model comments), so "customer"
// is an aggregation over those two tables grouped by phone number, done in
// JS rather than a SQL groupBy (need per-row customerName/createdAt to pick
// the most recent name, which Prisma's groupBy _max can't give us for a
// string field). Kept local to this module rather than importing
// OrderModule/BookingModule, per CLAUDE.md's module-independence principle
// (same approach ReviewRepository.placeExists uses for `places`).
@Injectable()
export class CustomerRepository {
  constructor(private readonly prisma: PrismaService) {}

  async listAggregate(
    placeId: string,
  ): Promise<Map<string, CustomerSummary>> {
    const [orders, bookings, blocks] = await Promise.all([
      this.prisma.order.findMany({
        where: { placeId, deletedAt: null, customerPhone: { not: null } },
        select: {
          customerName: true,
          customerPhone: true,
          totalAmount: true,
          createdAt: true,
        },
      }),
      this.prisma.booking.findMany({
        where: { placeId, deletedAt: null, customerPhone: { not: null } },
        select: { customerName: true, customerPhone: true, createdAt: true },
      }),
      this.prisma.customerBlock.findMany({
        where: { placeId },
        select: { customerPhone: true },
      }),
    ]);

    const blocked = new Set(blocks.map((b) => b.customerPhone));
    const byPhone = new Map<string, CustomerSummary>();

    const touch = (
      phone: string,
      name: string,
      createdAt: Date,
      amount: number,
      isOrder: boolean,
    ) => {
      const existing = byPhone.get(phone);
      if (!existing) {
        byPhone.set(phone, {
          customerName: name,
          customerPhone: phone,
          ordersCount: isOrder ? 1 : 0,
          bookingsCount: isOrder ? 0 : 1,
          totalSpent: amount,
          lastActivityAt: createdAt,
          isBlocked: blocked.has(phone),
        });
        return;
      }
      if (isOrder) {
        existing.ordersCount += 1;
        existing.totalSpent += amount;
      } else {
        existing.bookingsCount += 1;
      }
      if (createdAt > existing.lastActivityAt) {
        existing.lastActivityAt = createdAt;
        existing.customerName = name;
      }
    };

    for (const order of orders) {
      touch(order.customerPhone!, order.customerName, order.createdAt, order.totalAmount, true);
    }
    for (const booking of bookings) {
      touch(booking.customerPhone!, booking.customerName, booking.createdAt, 0, false);
    }

    return byPhone;
  }

  async getDetail(
    placeId: string,
    phone: string,
  ): Promise<CustomerDetail | null> {
    const [recentOrders, recentBookings, isBlocked] = await Promise.all([
      this.prisma.order.findMany({
        where: { placeId, customerPhone: phone, deletedAt: null },
        include: { items: true },
        orderBy: { createdAt: 'desc' },
        take: RECENT_TAKE,
      }),
      this.prisma.booking.findMany({
        where: { placeId, customerPhone: phone, deletedAt: null },
        orderBy: { bookingTime: 'desc' },
        take: RECENT_TAKE,
      }),
      this.isBlocked(placeId, phone),
    ]);

    if (recentOrders.length === 0 && recentBookings.length === 0) {
      return null;
    }

    const [ordersCount, bookingsCount, totalSpentAgg] = await Promise.all([
      this.prisma.order.count({
        where: { placeId, customerPhone: phone, deletedAt: null },
      }),
      this.prisma.booking.count({
        where: { placeId, customerPhone: phone, deletedAt: null },
      }),
      this.prisma.order.aggregate({
        where: { placeId, customerPhone: phone, deletedAt: null },
        _sum: { totalAmount: true },
      }),
    ]);

    const latestOrder = recentOrders[0];
    const latestBooking = recentBookings[0];
    const latest =
      !latestOrder || (latestBooking && latestBooking.createdAt > latestOrder.createdAt)
        ? latestBooking
        : latestOrder;

    return {
      customerName: latest?.customerName ?? phone,
      customerPhone: phone,
      ordersCount,
      bookingsCount,
      totalSpent: totalSpentAgg._sum.totalAmount ?? 0,
      lastActivityAt: latest?.createdAt ?? new Date(0),
      isBlocked,
      recentOrders,
      recentBookings,
    };
  }

  isBlocked(placeId: string, phone: string): Promise<boolean> {
    return this.prisma.customerBlock
      .findUnique({
        where: { placeId_customerPhone: { placeId, customerPhone: phone } },
      })
      .then((row) => row !== null);
  }

  block(placeId: string, phone: string): Promise<void> {
    return this.prisma.customerBlock
      .upsert({
        where: { placeId_customerPhone: { placeId, customerPhone: phone } },
        create: { placeId, customerPhone: phone },
        update: {},
      })
      .then(() => undefined);
  }

  async unblock(placeId: string, phone: string): Promise<void> {
    await this.prisma.customerBlock.deleteMany({
      where: { placeId, customerPhone: phone },
    });
  }
}
