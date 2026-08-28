import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { BookingService } from './services/booking.service';
import { listBookingsSchema } from './dto/list-bookings.dto';
import type { ListBookingsDto } from './dto/list-bookings.dto';
import { createBookingSchema } from './dto/create-booking.dto';
import type { CreateBookingDto } from './dto/create-booking.dto';
import { updateBookingStatusSchema } from './dto/update-booking-status.dto';
import type { UpdateBookingStatusDto } from './dto/update-booking-status.dto';

// Mikka Business booking (table reservation) management — every route is
// ADMIN-only, mirroring OrderController. Bookings are staff-entered (no
// customer-facing reservation flow exists yet).
@Controller('places/:placeId/bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  @Get()
  list(
    @Param('placeId') placeId: string,
    @Query(new ZodValidationPipe(listBookingsSchema)) query: ListBookingsDto,
  ) {
    return this.bookingService.list(placeId, query);
  }

  @Get('stats')
  getStats(@Param('placeId') placeId: string) {
    return this.bookingService.getStats(placeId);
  }

  @Post()
  create(
    @Param('placeId') placeId: string,
    @Body(new ZodValidationPipe(createBookingSchema)) dto: CreateBookingDto,
  ) {
    return this.bookingService.create(placeId, dto);
  }

  @Patch(':bookingId/status')
  updateStatus(
    @Param('placeId') placeId: string,
    @Param('bookingId') bookingId: string,
    @Body(new ZodValidationPipe(updateBookingStatusSchema))
    dto: UpdateBookingStatusDto,
  ) {
    return this.bookingService.updateStatus(placeId, bookingId, dto.status);
  }

  @Delete(':bookingId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Param('placeId') placeId: string,
    @Param('bookingId') bookingId: string,
  ): Promise<void> {
    await this.bookingService.remove(placeId, bookingId);
  }
}
