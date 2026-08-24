import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PlaceRepository } from '../../place/repositories/place.repository';
import { ProductRepository } from '../repositories/product.repository';
import { ProductStatus } from '../../../generated/prisma/client';
import type { Product, Prisma } from '../../../generated/prisma/client';
import type { CreateProductDto } from '../dto/create-product.dto';
import type { UpdateProductDto } from '../dto/update-product.dto';
import type { ListProductsDto } from '../dto/list-products.dto';
import type {
  ProductListResult,
  ProductStats,
} from '../types/product-list.type';

@Injectable()
export class ProductService {
  constructor(
    private readonly productRepository: ProductRepository,
    private readonly placeRepository: PlaceRepository,
  ) {}

  private static computeStatus(
    quantity: number,
    lowStockThreshold: number,
  ): ProductStatus {
    if (quantity <= 0) return ProductStatus.OUT_OF_STOCK;
    if (quantity <= lowStockThreshold) return ProductStatus.LOW_STOCK;
    return ProductStatus.IN_STOCK;
  }

  private async requirePlace(placeId: string): Promise<void> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
  }

  async findById(placeId: string, id: string): Promise<Product> {
    const product = await this.productRepository.findById(placeId, id);
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return product;
  }

  async list(
    placeId: string,
    dto: ListProductsDto,
  ): Promise<ProductListResult> {
    await this.requirePlace(placeId);
    const { items, total } = await this.productRepository.findMany({
      placeId,
      page: dto.page,
      limit: dto.limit,
      search: dto.search,
      status: dto.status,
    });
    return { items, total, page: dto.page, limit: dto.limit };
  }

  async getStats(placeId: string): Promise<ProductStats> {
    await this.requirePlace(placeId);
    return this.productRepository.getStats(placeId);
  }

  async create(placeId: string, dto: CreateProductDto): Promise<Product> {
    await this.requirePlace(placeId);

    const existing = await this.productRepository.findBySku(placeId, dto.sku);
    if (existing) {
      throw new ConflictException(
        'A product with this SKU already exists for this place',
      );
    }

    return this.productRepository.create({
      place: { connect: { id: placeId } },
      name: dto.name,
      sku: dto.sku,
      quantity: dto.quantity,
      lowStockThreshold: dto.lowStockThreshold,
      status: ProductService.computeStatus(dto.quantity, dto.lowStockThreshold),
    });
  }

  async update(
    placeId: string,
    id: string,
    dto: UpdateProductDto,
  ): Promise<Product> {
    const product = await this.findById(placeId, id);

    if (dto.sku !== undefined && dto.sku !== product.sku) {
      const existing = await this.productRepository.findBySku(placeId, dto.sku);
      if (existing) {
        throw new ConflictException(
          'A product with this SKU already exists for this place',
        );
      }
    }

    const data: Prisma.ProductUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.sku !== undefined) data.sku = dto.sku;
    if (dto.lowStockThreshold !== undefined) {
      data.lowStockThreshold = dto.lowStockThreshold;
      data.status = ProductService.computeStatus(
        product.quantity,
        dto.lowStockThreshold,
      );
    }

    return this.productRepository.update(id, data);
  }

  async adjustStock(
    placeId: string,
    id: string,
    delta: number,
  ): Promise<Product> {
    const product = await this.findById(placeId, id);

    const quantity = product.quantity + delta;
    if (quantity < 0) {
      throw new ConflictException('Stock cannot go below zero');
    }

    return this.productRepository.update(id, {
      quantity,
      status: ProductService.computeStatus(quantity, product.lowStockThreshold),
    });
  }

  async remove(placeId: string, id: string): Promise<void> {
    await this.findById(placeId, id);
    await this.productRepository.softDelete(id);
  }
}
