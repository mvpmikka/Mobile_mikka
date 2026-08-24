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
import { ProductService } from './services/product.service';
import { listProductsSchema } from './dto/list-products.dto';
import type { ListProductsDto } from './dto/list-products.dto';
import { createProductSchema } from './dto/create-product.dto';
import type { CreateProductDto } from './dto/create-product.dto';
import { updateProductSchema } from './dto/update-product.dto';
import type { UpdateProductDto } from './dto/update-product.dto';
import { adjustStockSchema } from './dto/adjust-stock.dto';
import type { AdjustStockDto } from './dto/adjust-stock.dto';

// Mikka Business inventory management — every route is ADMIN-only for now,
// there is no public/self-service storefront view of this data yet.
@Controller('places/:placeId/products')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Get()
  list(
    @Param('placeId') placeId: string,
    @Query(new ZodValidationPipe(listProductsSchema)) query: ListProductsDto,
  ) {
    return this.productService.list(placeId, query);
  }

  @Get('stats')
  getStats(@Param('placeId') placeId: string) {
    return this.productService.getStats(placeId);
  }

  @Post()
  create(
    @Param('placeId') placeId: string,
    @Body(new ZodValidationPipe(createProductSchema)) dto: CreateProductDto,
  ) {
    return this.productService.create(placeId, dto);
  }

  @Patch(':productId')
  update(
    @Param('placeId') placeId: string,
    @Param('productId') productId: string,
    @Body(new ZodValidationPipe(updateProductSchema)) dto: UpdateProductDto,
  ) {
    return this.productService.update(placeId, productId, dto);
  }

  @Post(':productId/adjust-stock')
  adjustStock(
    @Param('placeId') placeId: string,
    @Param('productId') productId: string,
    @Body(new ZodValidationPipe(adjustStockSchema)) dto: AdjustStockDto,
  ) {
    return this.productService.adjustStock(placeId, productId, dto.delta);
  }

  @Delete(':productId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @Param('placeId') placeId: string,
    @Param('productId') productId: string,
  ): Promise<void> {
    await this.productService.remove(placeId, productId);
  }
}
