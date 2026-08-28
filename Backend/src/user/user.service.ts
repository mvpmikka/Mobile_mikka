import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/client';
import { UserRepository } from './user.repository';
import { FollowRepository } from '../follow/repositories/follow.repository';
import type { Prisma, User } from '../../generated/prisma/client';
import type { UpdateProfileDto } from './dto/update-profile.dto';
import { toPrivateProfile, toPublicProfile } from './mappers/profile.mapper';
import type {
  PrivateProfile,
  PublicProfile,
  UserSearchResult,
} from './types/profile.type';
import type { AdminUserView } from './types/admin-user.type';

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

type ProfileCompletionFields = Pick<
  User,
  'username' | 'fullName' | 'gender' | 'birthDate'
>;

const USERNAME_CHANGE_COOLDOWN_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class UserService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly followRepository: FollowRepository,
  ) {}

  findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findByEmail(email);
  }

  findByUsername(username: string): Promise<User | null> {
    return this.userRepository.findByUsername(username);
  }

  findById(id: string): Promise<User | null> {
    return this.userRepository.findById(id);
  }

  create(data: Prisma.UserCreateInput): Promise<User> {
    return this.userRepository.create(data);
  }

  update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return this.userRepository.update(id, data);
  }

  // Single source of truth for "is this profile usable yet" — called after
  // every profile-relevant write (registration, OAuth callback, profile
  // update) regardless of signup method. See docs/foundation.md #3.
  computeProfileCompleted(user: ProfileCompletionFields): boolean {
    return Boolean(
      user.username && user.fullName && user.gender && user.birthDate,
    );
  }

  async isUsernameAvailable(username: string): Promise<boolean> {
    const existing = await this.userRepository.findByUsername(username);
    return !existing;
  }

  // viewerId is undefined for an anonymous caller (GET /users/:username has
  // no guard) — isFollowedByMe is just false in that case, not omitted.
  async getPublicProfile(
    username: string,
    viewerId?: string,
  ): Promise<PublicProfile> {
    const user = await this.userRepository.findByUsername(username);
    if (!user || !user.username) {
      throw new NotFoundException('User not found');
    }
    const [followersCount, followingCount, isFollowedByMe] = await Promise.all([
      this.followRepository.countFollowers(user.id),
      this.followRepository.countFollowing(user.id),
      viewerId
        ? this.followRepository.existsDirectional(viewerId, user.id)
        : Promise.resolve(false),
    ]);
    return toPublicProfile(
      { ...user, username: user.username },
      { followersCount, followingCount },
      isFollowedByMe,
    );
  }

  async getPrivateProfile(userId: string): Promise<PrivateProfile> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const [followersCount, followingCount] = await Promise.all([
      this.followRepository.countFollowers(userId),
      this.followRepository.countFollowing(userId),
    ]);
    return toPrivateProfile(user, { followersCount, followingCount });
  }

  async updateProfile(
    userId: string,
    updates: UpdateProfileDto,
  ): Promise<User> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isChangingUsername =
      updates.username !== undefined && updates.username !== user.username;

    if (isChangingUsername) {
      // Fast, friendly rejection for the common (uncontested) case — not
      // the safety net. The atomic write below is what actually guarantees
      // correctness under concurrent requests; see updateIfUsernameCooldownElapsed.
      const existing = await this.userRepository.findByUsername(
        updates.username!,
      );
      if (existing) {
        throw new ConflictException('This username is already taken');
      }
    }

    const data: Prisma.UserUpdateInput = {};
    if (isChangingUsername) {
      data.username = updates.username;
      data.usernameUpdatedAt = new Date();
    }
    if (updates.fullName !== undefined) {
      data.fullName = updates.fullName;
    }
    if (updates.gender !== undefined) {
      data.gender = updates.gender;
    }
    if (updates.birthDate !== undefined) {
      data.birthDate = updates.birthDate;
    }
    if (updates.avatarUrl !== undefined) {
      data.avatarUrl = updates.avatarUrl;
    }
    if (updates.bio !== undefined) {
      data.bio = updates.bio;
    }

    const merged: ProfileCompletionFields = {
      username: (data.username as string | undefined) ?? user.username,
      fullName: (data.fullName as string | undefined) ?? user.fullName,
      gender: (data.gender as User['gender'] | undefined) ?? user.gender,
      birthDate: (data.birthDate as Date | undefined) ?? user.birthDate,
    };
    const profileCompleted = this.computeProfileCompleted(merged);
    if (profileCompleted !== user.profileCompleted) {
      data.profileCompleted = profileCompleted;
    }

    if (!isChangingUsername) {
      return this.userRepository.update(userId, data);
    }

    // Username change: cooldown check + uniqueness + write happen as one
    // atomic conditional UPDATE (see UserRepository), so a concurrent
    // request cannot read a stale "cooldown passed" state and slip through.
    try {
      const cooldownCutoff = new Date(
        Date.now() - USERNAME_CHANGE_COOLDOWN_DAYS * DAY_MS,
      );
      const updated = await this.userRepository.updateIfUsernameCooldownElapsed(
        userId,
        cooldownCutoff,
        data,
      );
      if (!updated) {
        const latest = await this.userRepository.findById(userId);
        if (!latest) {
          throw new NotFoundException('User not found');
        }
        const cooldownEndsAt = new Date(
          (latest.usernameUpdatedAt ?? latest.createdAt).getTime() +
            USERNAME_CHANGE_COOLDOWN_DAYS * DAY_MS,
        );
        throw new ConflictException(
          `Username can next be changed on ${cooldownEndsAt.toISOString()}`,
        );
      }
      return updated;
    } catch (error) {
      if (
        error instanceof PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('This username is already taken');
      }
      throw error;
    }
  }

  async search(
    query: string,
    currentUserId: string,
  ): Promise<UserSearchResult[]> {
    const rows = await this.userRepository.searchPublic(
      query,
      currentUserId,
      20,
    );
    return rows
      .filter((user) => user.username !== null)
      .map((user) => ({ ...user, username: user.username! }));
  }

  async listForAdmin(
    page: number,
    limit: number,
    search?: string,
  ): Promise<PaginatedResult<AdminUserView>> {
    const { items, total } = await this.userRepository.findManyAdmin(
      page,
      limit,
      search,
    );
    return { items, total, page, limit };
  }

  async getForAdmin(id: string): Promise<AdminUserView> {
    const user = await this.userRepository.findByIdAdmin(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  // Ban itself is a pure User-domain state change; revoking the banned
  // user's refresh tokens (so the ban takes effect immediately, not after
  // their session naturally expires) is orchestrated by AdminService,
  // which is where the cross-module reach into Auth's TokenService
  // belongs — see docs/foundation.md.
  async ban(id: string, requestedByUserId: string): Promise<AdminUserView> {
    if (id === requestedByUserId) {
      throw new BadRequestException("You can't ban your own account");
    }
    await this.getForAdmin(id);
    return this.userRepository.setBanned(id, true);
  }

  async unban(id: string): Promise<void> {
    await this.getForAdmin(id);
    await this.userRepository.setBanned(id, false);
  }

  // Pure User-domain state change (soft-delete + PII scrub), mirroring
  // ban()'s split: session revocation is a cross-module concern and is
  // orchestrated by the caller (AuthService), not here — see docs/foundation.md.
  async deleteAccount(id: string): Promise<void> {
    await this.userRepository.anonymizeAndSoftDelete(id);
  }
}
