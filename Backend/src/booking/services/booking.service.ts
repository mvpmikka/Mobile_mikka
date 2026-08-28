import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PlaceRepository } from '../../place/repositories/place.repository';
import { BookingRepository } from '../repositories/booking.repository';
import { BookingStatus } from '../../../generated/prisma/client';
import type { Booking } from '../../../generated/prisma/client';
import type { CreateBookingDto } from '../dto/create-booking.dto';
import type { ListBookingsDto } from '../dto/list-bookings.dto';
import type { BookingListResult, BookingStats } from '../types/booking-list.type';

// Terminal states — once a booking reaches these, staff can no longer move
// it (same reasoning as OrderService.TERMINAL_STATUSES).
const TERMINAL_STATUSES: BookingStatus[] = [
  BookingStatus.COMPLETED,
  BookingStatus.CANCELLED,
];

@Injectable()
export class BookingService {
  constructor(
    private readonly bookingRepository: BookingRepository,
    private readonly placeRepository: PlaceRepository,
  ) {}

  private async requirePlace(placeId: string): Promise<void> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
  }

  async findById(placeId: string, id: string): Promise<Booking> {
    const booking = await this.bookingRepository.findById(placeId, id);
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    return booking;
  }

  async list(placeId: string, dto: ListBookingsDto): Promise<BookingListResult> {
    await this.requirePlace(placeId);
    const { items, total } = await this.bookingRepository.findMany({
      placeId,
      page: dto.page,
      limit: dto.limit,
      search: dto.search,
      status: dto.status,
      date: dto.date,
    });
    return { items, total, page: dto.page, limit: dto.limit };
  }

  async getStats(placeId: string): Promise<BookingStats> {
    await this.requirePlace(placeId);
    return this.bookingRepository.getStats(placeId);
  }

  async create(placeId: string, dto: CreateBookingDto): Promise<Booking> {
    await this.requirePlace(placeId);

    return this.bookingRepository.create(placeId, {
      customerName: dto.customerName,
      customerPhone: dto.customerPhone,
      bookingTime: dto.bookingTime,
      guests: dto.guests,
      tableLabel: dto.tableLabel,
      note: dto.note,
    });
  }

  async updateStatus(
    placeId: string,
    id: string,
    status: BookingStatus,
  ): Promise<Booking> {
    const booking = await this.findById(placeId, id);

    if (TERMINAL_STATUSES.includes(booking.status)) {
      throw new ConflictException(
        `Booking is already ${booking.status.toLowerCase()} and cannot change status`,
      );
    }

    return this.bookingRepository.updateStatus(id, status);
  }

  async remove(placeId: string, id: string): Promise<void> {
    await this.findById(placeId, id);
    await this.bookingRepository.softDelete(id);
  }
}
