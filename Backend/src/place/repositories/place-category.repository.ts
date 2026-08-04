import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { Prisma, PlaceCategory } from '../../../generated/prisma/client';

@Injectable()
export class PlaceCategoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  findAll(): Promise<PlaceCategory[]> {
    return this.prisma.placeCategory.findMany({
      where: { deletedAt: null },
      orderBy: { name: 'asc' },
    });
  }

  findById(id: string): Promise<PlaceCategory | null> {
    return this.prisma.placeCategory.findUnique({
      where: { id, deletedAt: null },
    });
  }

  findBySlug(slug: string): Promise<PlaceCategory | null> {
    return this.prisma.placeCategory.findUnique({
      where: { slug, deletedAt: null },
    });
  }

  findByNameCaseInsensitive(name: string): Promise<PlaceCategory | null> {
    return this.prisma.placeCategory.findFirst({
      where: { name: { equals: name, mode: 'insensitive' }, deletedAt: null },
    });
  }

  create(data: Prisma.PlaceCategoryCreateInput): Promise<PlaceCategory> {
    return this.prisma.placeCategory.create({ data });
  }

  update(
    id: string,
    data: Prisma.PlaceCategoryUpdateInput,
  ): Promise<PlaceCategory> {
    return this.prisma.placeCategory.update({ where: { id }, data });
  }

  softDelete(id: string): Promise<PlaceCategory> {
    return this.prisma.placeCategory.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
