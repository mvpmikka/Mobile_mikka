import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma, OrderStatus } from '../../../generated/prisma/client';
import type { OrderStats, OrderWithItems } from '../types/order-list.type';

export interface FindManyParams {
  placeId: string;
  page: number;
  limit: number;
  search?: string;
  status?: OrderStatus;
}

export interface CreateOrderItemInput {
  name: string;
  quantity: number;
  unitPrice: number;
}

@Injectable()
export class OrderRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(placeId: string, id: string): Promise<OrderWithItems | null> {
    return this.prisma.order.findFirst({
      where: { id, placeId, deletedAt: null },
      include: { items: true },
    });
  }

  async findMany(
    params: FindManyParams,
  ): Promise<{ items: OrderWithItems[]; total: number }> {
    const where: Prisma.OrderWhereInput = {
      placeId: params.placeId,
      deletedAt: null,
      ...(params.status ? { status: params.status } : {}),
      ...(params.search
        ? {
            OR: [
              { customerName: { contains: params.search, mode: 'insensitive' } },
              { customerPhone: { contains: params.search, mode: 'insensitive' } },
              { id: { contains: params.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: { items: true },
        orderBy: { createdAt: 'desc' },
        skip: (params.page - 1) * params.limit,
        take: params.limit,
      }),
      this.prisma.order.count({ where }),
    ]);

    return { items, total };
  }

  async getStats(placeId: string): Promise<OrderStats> {
    const where = { placeId, deletedAt: null } as const;
    const [newCount, acceptedCount, preparingCount, readyCount, completedCount, cancelledCount] =
      await Promise.all([
        this.prisma.order.count({ where: { ...where, status: OrderStatus.NEW } }),
        this.prisma.order.count({ where: { ...where, status: OrderStatus.ACCEPTED } }),
        this.prisma.order.count({ where: { ...where, status: OrderStatus.PREPARING } }),
        this.prisma.order.count({ where: { ...where, status: OrderStatus.READY } }),
        this.prisma.order.count({ where: { ...where, status: OrderStatus.COMPLETED } }),
        this.prisma.order.count({ where: { ...where, status: OrderStatus.CANCELLED } }),
      ]);
    return {
      newCount,
      acceptedCount,
      preparingCount,
      readyCount,
      completedCount,
      cancelledCount,
    };
  }

  create(
    placeId: string,
    data: {
      customerName: string;
      customerPhone?: string;
      totalAmount: number;
      items: CreateOrderItemInput[];
    },
  ): Promise<OrderWithItems> {
    return this.prisma.order.create({
      data: {
        place: { connect: { id: placeId } },
        customerName: data.customerName,
        customerPhone: data.customerPhone,
        totalAmount: data.totalAmount,
        items: { create: data.items },
      },
      include: { items: true },
    });
  }

  updateStatus(id: string, status: OrderStatus): Promise<OrderWithItems> {
    return this.prisma.order.update({
      where: { id },
      data: { status },
      include: { items: true },
    });
  }

  softDelete(id: string): Promise<OrderWithItems> {
    return this.prisma.order.update({
      where: { id },
      data: { deletedAt: new Date() },
      include: { items: true },
    });
  }
}
