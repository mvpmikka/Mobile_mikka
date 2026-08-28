import { Injectable, NotFoundException } from '@nestjs/common';
import { PlaceRepository } from '../../place/repositories/place.repository';
import { CustomerRepository } from '../repositories/customer.repository';
import type { ListCustomersDto } from '../dto/list-customers.dto';
import type { CustomerDetail, CustomerListResult } from '../types/customer.type';

@Injectable()
export class CustomerService {
  constructor(
    private readonly customerRepository: CustomerRepository,
    private readonly placeRepository: PlaceRepository,
  ) {}

  private async requirePlace(placeId: string): Promise<void> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
  }

  async list(placeId: string, dto: ListCustomersDto): Promise<CustomerListResult> {
    await this.requirePlace(placeId);

    const byPhone = await this.customerRepository.listAggregate(placeId);
    let items = Array.from(byPhone.values());

    if (dto.search) {
      const needle = dto.search.toLowerCase();
      items = items.filter(
        (c) =>
          c.customerName.toLowerCase().includes(needle) ||
          c.customerPhone.includes(needle),
      );
    }

    items.sort(
      (a, b) => b.lastActivityAt.getTime() - a.lastActivityAt.getTime(),
    );

    const total = items.length;
    const start = (dto.page - 1) * dto.limit;
    const page = items.slice(start, start + dto.limit);

    return { items: page, total, page: dto.page, limit: dto.limit };
  }

  async getDetail(placeId: string, phone: string): Promise<CustomerDetail> {
    await this.requirePlace(placeId);
    const detail = await this.customerRepository.getDetail(placeId, phone);
    if (!detail) {
      throw new NotFoundException('Customer not found');
    }
    return detail;
  }

  async block(placeId: string, phone: string): Promise<void> {
    await this.requirePlace(placeId);
    await this.customerRepository.block(placeId, phone);
  }

  async unblock(placeId: string, phone: string): Promise<void> {
    await this.requirePlace(placeId);
    await this.customerRepository.unblock(placeId, phone);
  }
}
