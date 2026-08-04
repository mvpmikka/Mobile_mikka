import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { SavedPlaceItem } from '../types/saved-place.type';

const placeSummarySelect = {
  id: true,
  name: true,
  latitude: true,
  longitude: true,
  status: true,
  category: { select: { id: true, name: true } },
} as const;

@Injectable()
export class SavedPlaceRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Upsert, not create — save() is idempotent by design (see SavedPlace
  // model comment), so a second save of the same place is a no-op rather
  // than a unique-constraint error the service would have to catch.
  async save(userId: string, placeId: string): Promise<void> {
    await this.prisma.savedPlace.upsert({
      where: { userId_placeId: { userId, placeId } },
      create: { user: { connect: { id: userId } }, place: { connect: { id: placeId } } },
      update: {},
    });
  }

  async unsave(userId: string, placeId: string): Promise<void> {
    await this.prisma.savedPlace.deleteMany({ where: { userId, placeId } });
  }

  async findManyByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: SavedPlaceItem[]; total: number }> {
    const where = { userId };
    const [rows, total] = await Promise.all([
      this.prisma.savedPlace.findMany({
        where,
        include: { place: { select: placeSummarySelect } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.savedPlace.count({ where }),
    ]);

    const items: SavedPlaceItem[] = rows.map((row) => ({
      ...row.place,
      savedAt: row.createdAt,
    }));
    return { items, total };
  }

  countByPlace(placeId: string): Promise<number> {
    return this.prisma.savedPlace.count({ where: { placeId } });
  }

  // Read-only against `places` — kept minimal and local to this module
  // rather than importing PlaceModule/PlaceService, per CLAUDE.md's
  // module-independence principle (same approach Review/CheckIn/Search use).
  async placeExists(placeId: string): Promise<boolean> {
    const place = await this.prisma.place.findUnique({
      where: { id: placeId, deletedAt: null },
      select: { id: true },
    });
    return place !== null;
  }
}