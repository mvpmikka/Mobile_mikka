import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma, ProductStatus } from '../../../generated/prisma/client';
import type { Product } from '../../../generated/prisma/client';
import type { ProductStats } from '../types/product-list.type';

export interface FindManyParams {
  placeId: string;
  page: number;
  limit: number;
  search?: string;
  status?: ProductStatus;
}

@Injectable()
export class ProductRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(placeId: string, id: string): Promise<Product | null> {
    return this.prisma.product.findFirst({
      where: { id, placeId, deletedAt: null },
    });
  }

  findBySku(placeId: string, sku: string): Promise<Product | null> {
    return this.prisma.product.findFirst({
      where: { placeId, sku, deletedAt: null },
    });
  }

  async findMany(
    params: FindManyParams,
  ): Promise<{ items: Product[]; total: number }> {
    const where: Prisma.ProductWhereInput = {
      placeId: params.placeId,
      deletedAt: null,
      ...(params.status ? { status: params.status } : {}),
      ...(params.search
        ? {
            OR: [
              { name: { contains: params.search, mode: 'insensitive' } },
              { sku: { contains: params.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip: (params.page - 1) * params.limit,
        take: params.limit,
      }),
      this.prisma.product.count({ where }),
    ]);

    return { items, total };
  }

  async getStats(placeId: string): Promise<ProductStats> {
    const [totalProducts, lowStock, outOfStock] = await Promise.all([
      this.prisma.product.count({ where: { placeId, deletedAt: null } }),
      this.prisma.product.count({
        where: { placeId, deletedAt: null, status: ProductStatus.LOW_STOCK },
      }),
      this.prisma.product.count({
        where: { placeId, deletedAt: null, status: ProductStatus.OUT_OF_STOCK },
      }),
    ]);
    return { totalProducts, lowStock, outOfStock };
  }

  create(data: Prisma.ProductCreateInput): Promise<Product> {
    return this.prisma.product.create({ data });
  }

  update(id: string, data: Prisma.ProductUpdateInput): Promise<Product> {
    return this.prisma.product.update({ where: { id }, data });
  }

  softDelete(id: string): Promise<Product> {
    return this.prisma.product.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
