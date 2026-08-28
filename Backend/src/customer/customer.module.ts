import { Module } from '@nestjs/common';
import { PlaceModule } from '../place/place.module';
import { CustomerController } from './customer.controller';
import { CustomerService } from './services/customer.service';
import { CustomerRepository } from './repositories/customer.repository';

@Module({
  imports: [PlaceModule],
  controllers: [CustomerController],
  providers: [CustomerService, CustomerRepository],
})
export class CustomerModule {}
