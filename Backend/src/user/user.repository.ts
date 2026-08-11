import { Injectable } from '@nestjs/common';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/client';
import { PrismaService } from '../prisma/prisma.service';
import type { Prisma, User } from '../../generated/prisma/client';
import type { AdminUserView } from './types/admin-user.type';

const userSearchSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

// Deliberately wider than PrivateProfile/PublicProfile (email, role,
// isBanned included) — this projection is only ever reachable through
// AdminModule's ADMIN-gated routes, never returned to the user it
// describes or to any other caller.
const adminUserSelect = {
  id: true,
  email: true,
  username: true,
  fullName: true,
  role: true,
  isBanned: true,
  isEmailVerified: true,
  createdAt: true,
} as const;

@Injectable()
export class UserRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email, deletedAt: null } });
  }

  findByUsername(username: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { username, deletedAt: null },
    });
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id, deletedAt: null } });
  }

  create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return this.prisma.user.update({ where: { id }, data });
  }

  // Folds the cooldown check into the UPDATE's WHERE clause so the check
  // and the write happen as one atomic statement — no gap for a concurrent
  // request to read a stale "cooldown passed" state. Returns null if the
  // row didn't match (cooldown still active); lets a unique-constraint
  // violation on username (P2002) propagate to the caller.
  async updateIfUsernameCooldownElapsed(
    id: string,
    cooldownCutoff: Date,
    data: Prisma.UserUpdateInput,
  ): Promise<User | null> {
    try {
      return await this.prisma.user.update({
        where: {
          id,
          OR: [
            { username: null },
            { usernameUpdatedAt: null },
            { usernameUpdatedAt: { lte: cooldownCutoff } },
          ],
        },
        data,
      });
    } catch (error) {
      if (
        error instanceof PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        return null;
      }
      throw error;
    }
  }

  async findManyAdmin(
    page: number,
    limit: number,
    search?: string,
  ): Promise<{ items: AdminUserView[]; total: number }> {
    const where: Prisma.UserWhereInput = {
      deletedAt: null,
      ...(search
        ? {
            OR: [
              { email: { contains: search, mode: 'insensitive' } },
              { username: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: adminUserSelect,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.user.count({ where }),
    ]);
    return { items, total };
  }

  // Excludes the caller. Rows always have a non-null username (a user
  // without one hasn't finished onboarding and shouldn't be discoverable
  // yet) even though Prisma's inferred type keeps it nullable — the caller
  // (UserService.search) is responsible for narrowing that.
  searchPublic(
    query: string,
    excludeUserId: string,
    limit: number,
  ): Promise<
    Array<{
      id: string;
      username: string | null;
      fullName: string | null;
      avatarUrl: string | null;
    }>
  > {
    return this.prisma.user.findMany({
      where: {
        deletedAt: null,
        isBanned: false,
        id: { not: excludeUserId },
        username: { not: null },
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { fullName: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: userSearchSelect,
      orderBy: { username: 'asc' },
      take: limit,
    });
  }

  findByIdAdmin(id: string): Promise<AdminUserView | null> {
    return this.prisma.user.findUnique({
      where: { id, deletedAt: null },
      select: adminUserSelect,
    });
  }

  setBanned(id: string, isBanned: boolean): Promise<AdminUserView> {
    return this.prisma.user.update({
      where: { id },
      data: { isBanned },
      select: adminUserSelect,
    });
  }
}
