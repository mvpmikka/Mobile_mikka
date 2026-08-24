import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PlaceRepository } from '../../place/repositories/place.repository';
import { OrderRepository } from '../repositories/order.repository';
import { OrderStatus } from '../../../generated/prisma/client';
import type { CreateOrderDto } from '../dto/create-order.dto';
import type { ListOrdersDto } from '../dto/list-orders.dto';
import type { OrderListResult, OrderStats, OrderWithItems } from '../types/order-list.type';

// Terminal states — once an order reaches these, staff can no longer move it
// (matches the Figma status tabs, which treat Completed/Cancelled as final).
const TERMINAL_STATUSES: OrderStatus[] = [OrderStatus.COMPLETED, OrderStatus.CANCELLED];

@Injectable()
export class OrderService {
  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly placeRepository: PlaceRepository,
  ) {}

  private async requirePlace(placeId: string): Promise<void> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
  }

  async findById(placeId: string, id: string): Promise<OrderWithItems> {
    const order = await this.orderRepository.findById(placeId, id);
    if (!order) {
      throw new NotFoundException('Order not found');
    }
    return order;
  }

  async list(placeId: string, dto: ListOrdersDto): Promise<OrderListResult> {
    await this.requirePlace(placeId);
    const { items, total } = await this.orderRepository.findMany({
      placeId,
      page: dto.page,
      limit: dto.limit,
      search: dto.search,
      status: dto.status,
    });
    return { items, total, page: dto.page, limit: dto.limit };
  }

  async getStats(placeId: string): Promise<OrderStats> {
    await this.requirePlace(placeId);
    return this.orderRepository.getStats(placeId);
  }

  async create(placeId: string, dto: CreateOrderDto): Promise<OrderWithItems> {
    await this.requirePlace(placeId);

    const totalAmount = dto.items.reduce(
      (sum, item) => sum + item.quantity * item.unitPrice,
      0,
    );

    return this.orderRepository.create(placeId, {
      customerName: dto.customerName,
      customerPhone: dto.customerPhone,
      totalAmount,
      items: dto.items,
    });
  }

  async updateStatus(
    placeId: string,
    id: string,
    status: OrderStatus,
  ): Promise<OrderWithItems> {
    const order = await this.findById(placeId, id);

    if (TERMINAL_STATUSES.includes(order.status)) {
      throw new ConflictException(
        `Order is already ${order.status.toLowerCase()} and cannot change status`,
      );
    }

    return this.orderRepository.updateStatus(id, status);
  }

  async remove(placeId: string, id: string): Promise<void> {
    await this.findById(placeId, id);
    await this.orderRepository.softDelete(id);
  }
}
