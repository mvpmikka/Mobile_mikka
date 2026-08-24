import { Module } from '@nestjs/common';
import { PlaceModule } from '../place/place.module';
import { OrderController } from './order.controller';
import { OrderService } from './services/order.service';
import { OrderRepository } from './repositories/order.repository';

@Module({
  imports: [PlaceModule],
  controllers: [OrderController],
  providers: [OrderService, OrderRepository],
})
export class OrderModule {}
