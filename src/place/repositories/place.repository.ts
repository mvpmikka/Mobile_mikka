import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import type { Place } from '../../../generated/prisma/client';
import type { PlaceListItem } from '../types/place-list.type';

export interface FindManyParams {
  page: number;
  limit: number;
  categoryId?: string;
}

export interface FindNearParams extends FindManyParams {
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface FindByRegionParams extends FindManyParams {
  regionId: string;
  latitude: number;
  longitude: number;
}

interface RawNearRow {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
  categoryId: string;
  categoryName: string;
  distanceMeters: number;
}

// Selected once, reused by both list paths — only what a list/map view
// displays. Never fetch what isn't rendered — see docs/foundation.md.
const placeListSelect = {
  id: true,
  name: true,
  latitude: true,
  longitude: true,
  status: true,
  category: { select: { id: true, name: true } },
} as const;

@Injectable()
export class PlaceRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Place | null> {
    return this.prisma.place.findUnique({ where: { id, deletedAt: null } });
  }

  async findMany(
    params: FindManyParams,
  ): Promise<{ items: PlaceListItem[]; total: number }> {
    const where: Prisma.PlaceWhereInput = {
      deletedAt: null,
      ...(params.categoryId ? { categoryId: params.categoryId } : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.place.findMany({
        where,
        select: placeListSelect,
        orderBy: { createdAt: 'desc' },
        skip: (params.page - 1) * params.limit,
        take: params.limit,
      }),
      this.prisma.place.count({ where }),
    ]);

    const items: PlaceListItem[] = rows.map((row) => ({
      ...row,
      distanceMeters: null,
    }));
    return { items, total };
  }

  // Spatial filtering/sorting has no Prisma Client equivalent — `location`
  // is an Unsupported column, so this goes through raw SQL. Prisma.sql's
  // tagged-template interpolation parameterizes values safely (not string
  // concatenation), so this remains injection-safe.
  async findNear(
    params: FindNearParams,
  ): Promise<{ items: PlaceListItem[]; total: number }> {
    const categoryFilter = params.categoryId
      ? Prisma.sql`AND p."categoryId" = ${params.categoryId}`
      : Prisma.empty;
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${params.longitude}, ${params.latitude}), 4326)::geography`;
    const offset = (params.page - 1) * params.limit;

    const rows = await this.prisma.$queryRaw<RawNearRow[]>`
      SELECT
        p.id, p.name, p.latitude, p.longitude, p.status,
        p."categoryId" AS "categoryId", c.name AS "categoryName",
        ST_Distance(p.location, ${point}) AS "distanceMeters"
      FROM places p
      JOIN place_categories c ON c.id = p."categoryId"
      WHERE p."deletedAt" IS NULL
        AND ST_DWithin(p.location, ${point}, ${params.radiusMeters})
        ${categoryFilter}
      ORDER BY "distanceMeters" ASC
      LIMIT ${params.limit} OFFSET ${offset}
    `;

    const items: PlaceListItem[] = rows.map((row) => ({
      id: row.id,
      name: row.name,
      latitude: row.latitude,
      longitude: row.longitude,
      status: row.status,
      category: { id: row.categoryId, name: row.categoryName },
      distanceMeters: row.distanceMeters,
    }));

    const countResult = await this.prisma.$queryRaw<[{ count: bigint }]>`
      SELECT COUNT(*)::bigint AS count
      FROM places p
      WHERE p."deletedAt" IS NULL
        AND ST_DWithin(p.location, ${point}, ${params.radiusMeters})
        ${categoryFilter}
    `;

    return { items, total: Number(countResult[0].count) };
  }

  // Point-in-polygon lookup used only when a radius search comes up empty
  // (see PlaceService.list) — resolves which seeded Region contains the
  // user's coordinates, via the same GiST index that backs the DB trigger.
  // Returns null if no seeded region covers this point (expected: see
  // Region model's placeholder-boundary caveat).
  async findRegionContaining(
    latitude: number,
    longitude: number,
  ): Promise<{ id: string; name: string } | null> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)`;
    const rows = await this.prisma.$queryRaw<{ id: string; name: string }[]>`
      SELECT id, name
      FROM regions
      WHERE ST_Contains(boundary, ${point})
      LIMIT 1
    `;
    return rows[0] ?? null;
  }

  // Widened fallback for when findNear's radius comes up empty — same
  // shape/select as findNear, but filtered by regionId (indexed) instead of
  // ST_DWithin. Still sorts by distance from the user's point so the
  // closest-in-region place comes first.
  async findByRegion(
    params: FindByRegionParams,
  ): Promise<{ items: PlaceListItem[]; total: number }> {
    const categoryFilter = params.categoryId
      ? Prisma.sql`AND p."categoryId" = ${params.categoryId}`
      : Prisma.empty;
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${params.longitude}, ${params.latitude}), 4326)::geography`;
    const offset = (params.page - 1) * params.limit;

    const rows = await this.prisma.$queryRaw<RawNearRow[]>`
      SELECT
        p.id, p.name, p.latitude, p.longitude, p.status,
        p."categoryId" AS "categoryId", c.name AS "categoryName",
        ST_Distance(p.location, ${point}) AS "distanceMeters"
      FROM places p
      JOIN place_categories c ON c.id = p."categoryId"
      WHERE p."deletedAt" IS NULL
        AND p."regionId" = ${params.regionId}
        ${categoryFilter}
      ORDER BY "distanceMeters" ASC
      LIMIT ${params.limit} OFFSET ${offset}
    `;

    const items: PlaceListItem[] = rows.map((row) => ({
      id: row.id,
      name: row.name,
      latitude: row.latitude,
      longitude: row.longitude,
      status: row.status,
      category: { id: row.categoryId, name: row.categoryName },
      distanceMeters: row.distanceMeters,
    }));

    const countResult = await this.prisma.$queryRaw<[{ count: bigint }]>`
      SELECT COUNT(*)::bigint AS count
      FROM places p
      WHERE p."deletedAt" IS NULL
        AND p."regionId" = ${params.regionId}
        ${categoryFilter}
    `;

    return { items, total: Number(countResult[0].count) };
  }

  countByCategory(categoryId: string): Promise<number> {
    return this.prisma.place.count({ where: { categoryId, deletedAt: null } });
  }

  create(data: Prisma.PlaceCreateInput): Promise<Place> {
    return this.prisma.place.create({ data });
  }

  update(id: string, data: Prisma.PlaceUpdateInput): Promise<Place> {
    return this.prisma.place.update({ where: { id }, data });
  }

  softDelete(id: string): Promise<Place> {
    return this.prisma.place.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
