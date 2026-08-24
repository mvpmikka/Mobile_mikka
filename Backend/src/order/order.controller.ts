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
import { OrderService } from './services/order.service';
import { listOrdersSchema } from './dto/list-orders.dto';
import type { ListOrdersDto } from './dto/list-orders.dto';
import { createOrderSchema } from './dto/create-order.dto';
import type { CreateOrderDto } from './dto/create-order.dto';
import { updateOrderStatusSchema } from './dto/update-order-status.dto';
import type { UpdateOrderStatusDto } from './dto/update-order-status.dto';

// Mikka Business order management — every route is ADMIN-only, mirroring
// ProductController. Orders are staff/POS-entered (no customer-facing
// ordering flow exists yet).
@Controller('places/:placeId/orders')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Get()
  list(
    @Param('placeId') placeId: string,
    @Query(new ZodValidationPipe(listOrdersSchema)) query: ListOrdersDto,
  ) {
    return this.orderService.list(placeId, query);
  }

  @Get('stats')
  getStats(@Param('placeId') placeId: string) {
    return this.orderService.getStats(placeId);
  }

  @Post()
  create(
    @Param('placeId') placeId: string,
    @Body(new ZodValidationPipe(createOrderSchema)) dto: CreateOrderDto,
  ) {
    return this.orderService.create(placeId, dto);
  }

  @Patch(':orderId/status')
  updateStatus(
    @Param('placeId') placeId: string,
    @Param('orderId') orderId: string,
    @Body(new ZodValidationPipe(updateOrderStatusSchema)) dto: UpdateOrderStatusDto,
  ) {
    return this.orderService.updateStatus(placeId, orderId, dto.status);
  }

  @Delete(':orderId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Param('placeId') placeId: string,
    @Param('orderId') orderId: string,
  ): Promise<void> {
    await this.orderService.remove(placeId, orderId);
  }
}
