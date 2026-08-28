import { Module } from '@nestjs/common';
import { PlaceModule } from '../place/place.module';
import { BookingController } from './booking.controller';
import { BookingService } from './services/booking.service';
import { BookingRepository } from './repositories/booking.repository';

@Module({
  imports: [PlaceModule],
  controllers: [BookingController],
  providers: [BookingService, BookingRepository],
})
export class BookingModule {}
