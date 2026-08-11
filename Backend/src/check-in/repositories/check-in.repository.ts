import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import type { CheckIn } from '../../../generated/prisma/client';
import type {
  CheckInWithPlace,
  PublicCheckInItem,
} from '../types/check-in.type';

const checkInWithPlaceInclude = {
  place: { select: { id: true, name: true } },
} as const;

// Enforced at the query level, not just by a narrower TS return type — see
// PublicCheckInItem's comment. A wider TS annotation alone wouldn't stop
// extra columns from actually being serialized in the response.
const publicCheckInSelect = {
  id: true,
  createdAt: true,
  place: { select: { id: true, name: true, latitude: true, longitude: true } },
} as const;

@Injectable()
export class CheckInRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<CheckIn | null> {
    return this.prisma.checkIn.findUnique({ where: { id, deletedAt: null } });
  }

  // Most recent active check-in by this user at this place — used to
  // enforce the cooldown window, not to guarantee anything at the DB
  // level (repeat check-ins at the same place are legitimate once the
  // cooldown passes, unlike Review's one-per-place rule).
  findMostRecentByUserAndPlace(
    userId: string,
    placeId: string,
  ): Promise<CheckIn | null> {
    return this.prisma.checkIn.findFirst({
      where: { userId, placeId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findManyByUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: CheckInWithPlace[]; total: number }> {
    const where: Prisma.CheckInWhereInput = { userId, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.checkIn.findMany({
        where,
        include: checkInWithPlaceInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.checkIn.count({ where }),
    ]);
    return { items, total };
  }

  async findManyByUserPublic(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: PublicCheckInItem[]; total: number }> {
    const where: Prisma.CheckInWhereInput = { userId, deletedAt: null };
    const [items, total] = await Promise.all([
      this.prisma.checkIn.findMany({
        where,
        select: publicCheckInSelect,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.checkIn.count({ where }),
    ]);
    return { items, total };
  }

  countByPlace(placeId: string): Promise<number> {
    return this.prisma.checkIn.count({ where: { placeId, deletedAt: null } });
  }

  create(data: Prisma.CheckInCreateInput): Promise<CheckIn> {
    return this.prisma.checkIn.create({ data });
  }

  softDelete(id: string): Promise<CheckIn> {
    return this.prisma.checkIn.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // Read-only against `users` — kept minimal and local to this module
  // rather than importing UserModule/UserService, same reasoning as
  // getDistanceToPlace below. Used to resolve GET /users/:username/check-ins'
  // path param to an id before the Privacy visibility check.
  async findUserIdByUsername(username: string): Promise<string | null> {
    const user = await this.prisma.user.findUnique({
      where: { username, deletedAt: null },
      select: { id: true },
    });
    return user?.id ?? null;
  }

  // Read-only against `places` — kept minimal and local to this module
  // rather than importing PlaceModule/PlaceService, per CLAUDE.md's
  // module-independence principle (same approach Search and Review use).
  // Returns null when the place doesn't exist (or is soft-deleted), so a
  // single query serves both the existence check and the distance value.
  async getDistanceToPlace(
    placeId: string,
    latitude: number,
    longitude: number,
  ): Promise<number | null> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography`;
    const rows = await this.prisma.$queryRaw<[{ distanceMeters: number }] | []>`
      SELECT ST_Distance(location, ${point}) AS "distanceMeters"
      FROM places
      WHERE id = ${placeId} AND "deletedAt" IS NULL
    `;
    return rows[0]?.distanceMeters ?? null;
  }
}
