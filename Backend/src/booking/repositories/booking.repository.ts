import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma, BookingStatus } from '../../../generated/prisma/client';
import type { Booking } from '../../../generated/prisma/client';
import type { BookingStats } from '../types/booking-list.type';

export interface FindManyParams {
  placeId: string;
  page: number;
  limit: number;
  search?: string;
  status?: BookingStatus;
  date?: string;
}

export interface CreateBookingInput {
  customerName: string;
  customerPhone?: string;
  bookingTime: Date;
  guests: number;
  tableLabel?: string;
  note?: string;
}

@Injectable()
export class BookingRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(placeId: string, id: string): Promise<Booking | null> {
    return this.prisma.booking.findFirst({
      where: { id, placeId, deletedAt: null },
    });
  }

  async findMany(
    params: FindManyParams,
  ): Promise<{ items: Booking[]; total: number }> {
    const where: Prisma.BookingWhereInput = {
      placeId: params.placeId,
      deletedAt: null,
      ...(params.status ? { status: params.status } : {}),
      ...(params.date ? { bookingTime: dayRange(params.date) } : {}),
      ...(params.search
        ? {
            OR: [
              {
                customerName: { contains: params.search, mode: 'insensitive' },
              },
              {
                customerPhone: { contains: params.search, mode: 'insensitive' },
              },
              { id: { contains: params.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        orderBy: { bookingTime: 'asc' },
        skip: (params.page - 1) * params.limit,
        take: params.limit,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return { items, total };
  }

  async getStats(placeId: string): Promise<BookingStats> {
    const where = { placeId, deletedAt: null } as const;
    const [
      pendingCount,
      confirmedCount,
      seatedCount,
      completedCount,
      cancelledCount,
    ] = await Promise.all([
      this.prisma.booking.count({
        where: { ...where, status: BookingStatus.PENDING },
      }),
      this.prisma.booking.count({
        where: { ...where, status: BookingStatus.CONFIRMED },
      }),
      this.prisma.booking.count({
        where: { ...where, status: BookingStatus.SEATED },
      }),
      this.prisma.booking.count({
        where: { ...where, status: BookingStatus.COMPLETED },
      }),
      this.prisma.booking.count({
        where: { ...where, status: BookingStatus.CANCELLED },
      }),
    ]);
    return {
      pendingCount,
      confirmedCount,
      seatedCount,
      completedCount,
      cancelledCount,
    };
  }

  create(placeId: string, data: CreateBookingInput): Promise<Booking> {
    return this.prisma.booking.create({
      data: {
        place: { connect: { id: placeId } },
        customerName: data.customerName,
        customerPhone: data.customerPhone,
        bookingTime: data.bookingTime,
        guests: data.guests,
        tableLabel: data.tableLabel,
        note: data.note,
      },
    });
  }

  updateStatus(id: string, status: BookingStatus): Promise<Booking> {
    return this.prisma.booking.update({
      where: { id },
      data: { status },
    });
  }

  softDelete(id: string): Promise<Booking> {
    return this.prisma.booking.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}

function dayRange(date: string): { gte: Date; lt: Date } {
  const start = new Date(`${date}T00:00:00.000Z`);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);
  return { gte: start, lt: end };
}
