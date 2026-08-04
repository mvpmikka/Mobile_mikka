import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import type { SearchResult } from '../types/search-result.type';

export interface SearchPlacesParams {
  query: string;
  page: number;
  limit: number;
  categoryId?: string;
  latitude?: number;
  longitude?: number;
  radiusMeters?: number;
}

interface RawSearchRow {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
  categoryId: string;
  categoryName: string;
  relevance: number;
  distanceMeters: number | null;
}

@Injectable()
export class SearchRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Matches on EITHER place name or category name similarity (GREATEST of
  // the two), so searching "gym" surfaces every Gym-category place even if
  // its business name doesn't contain the word. The `%` operator respects
  // Postgres's pg_trgm.similarity_threshold, so irrelevant near-zero
  // matches are filtered out at the DB level, not just sorted last.
  // `relevance` is only selected to drive ORDER BY — trimmed out of the
  // mapped response, a mobile list view has no use for a raw score.
  async searchPlaces(
    params: SearchPlacesParams,
  ): Promise<{ items: SearchResult[]; total: number }> {
    const categoryFilter = params.categoryId
      ? Prisma.sql`AND p."categoryId" = ${params.categoryId}`
      : Prisma.empty;

    const hasGeo =
      params.latitude !== undefined && params.longitude !== undefined;
    const point = hasGeo
      ? Prisma.sql`ST_SetSRID(ST_MakePoint(${params.longitude}, ${params.latitude}), 4326)::geography`
      : Prisma.empty;
    const geoFilter = hasGeo
      ? Prisma.sql`AND ST_DWithin(p.location, ${point}, ${params.radiusMeters})`
      : Prisma.empty;
    const distanceSelect = hasGeo
      ? Prisma.sql`ST_Distance(p.location, ${point})`
      : Prisma.sql`NULL`;

    const offset = (params.page - 1) * params.limit;

    const rows = await this.prisma.$queryRaw<RawSearchRow[]>`
      SELECT
        p.id, p.name, p.latitude, p.longitude, p.status,
        p."categoryId" AS "categoryId", c.name AS "categoryName",
        GREATEST(similarity(p.name, ${params.query}), similarity(c.name, ${params.query})) AS "relevance",
        ${distanceSelect} AS "distanceMeters"
      FROM places p
      JOIN place_categories c ON c.id = p."categoryId"
      WHERE p."deletedAt" IS NULL
        AND (p.name % ${params.query} OR c.name % ${params.query})
        ${categoryFilter}
        ${geoFilter}
      ORDER BY "relevance" DESC
      LIMIT ${params.limit} OFFSET ${offset}
    `;

    const items: SearchResult[] = rows.map((row) => ({
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
      JOIN place_categories c ON c.id = p."categoryId"
      WHERE p."deletedAt" IS NULL
        AND (p.name % ${params.query} OR c.name % ${params.query})
        ${categoryFilter}
        ${geoFilter}
    `;

    return { items, total: Number(countResult[0].count) };
  }
}
