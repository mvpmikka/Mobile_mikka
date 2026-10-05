import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ShortRepository } from '../repositories/short.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import type { CreateShortDto } from '../dto/create-short.dto';
import type { Short } from '../../../generated/prisma/client';
import type { PaginatedResult, ShortFeedItem } from '../types/short.type';

@Injectable()
export class ShortService {
  constructor(
    private readonly shortRepository: ShortRepository,
    private readonly friendshipRepository: FriendshipRepository,
  ) {}

  async create(userId: string, dto: CreateShortDto): Promise<ShortFeedItem> {
    if (dto.placeId) {
      const exists = await this.shortRepository.placeExists(dto.placeId);
      if (!exists) {
        throw new NotFoundException('Place not found');
      }
    }
    return this.shortRepository.create(userId, dto);
  }

  async remove(id: string, userId: string, isAdmin = false): Promise<void> {
    const short = await this.requireShort(id);
    if (short.userId !== userId && !isAdmin) {
      throw new ForbiddenException('You can only delete your own short');
    }
    await this.shortRepository.softDelete(id);
  }

  // Cross-user feed: friend ids are resolved once here, same orchestration
  // pattern as Story's feed building, and handed to the repository as a
  // plain array rather than the repository importing FriendshipModule
  // itself.
  async getFeed(
    viewerId: string | undefined,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<ShortFeedItem>> {
    const friendIds = viewerId
      ? await this.friendshipRepository.findAllFriendIds(viewerId)
      : [];
    const { items, total } = await this.shortRepository.findFeed(
      viewerId,
      friendIds,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async like(id: string, userId: string): Promise<void> {
    await this.requireShort(id);
    await this.shortRepository.like(userId, id);
  }

  async unlike(id: string, userId: string): Promise<void> {
    await this.requireShort(id);
    await this.shortRepository.unlike(userId, id);
  }

  private async requireShort(id: string): Promise<Short> {
    const short = await this.shortRepository.findById(id);
    if (!short) {
      throw new NotFoundException('Short not found');
    }
    return short;
  }
}
