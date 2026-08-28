import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { CustomerService } from './services/customer.service';
import { listCustomersSchema } from './dto/list-customers.dto';
import type { ListCustomersDto } from './dto/list-customers.dto';

// Mikka Business customer directory — an aggregation over Order/Booking
// rows grouped by phone number (see CustomerRepository), not a real table.
// Every route is ADMIN-only, same as Order/Booking/Product.
@Controller('places/:placeId/customers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class CustomerController {
  constructor(private readonly customerService: CustomerService) {}

  @Get()
  list(
    @Param('placeId') placeId: string,
    @Query(new ZodValidationPipe(listCustomersSchema)) query: ListCustomersDto,
  ) {
    return this.customerService.list(placeId, query);
  }

  @Get(':phone')
  getDetail(@Param('placeId') placeId: string, @Param('phone') phone: string) {
    return this.customerService.getDetail(placeId, phone);
  }

  @Post(':phone/block')
  @HttpCode(HttpStatus.NO_CONTENT)
  async block(
    @Param('placeId') placeId: string,
    @Param('phone') phone: string,
  ): Promise<void> {
    await this.customerService.block(placeId, phone);
  }

  @Post(':phone/unblock')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unblock(
    @Param('placeId') placeId: string,
    @Param('phone') phone: string,
  ): Promise<void> {
    await this.customerService.unblock(placeId, phone);
  }
}
