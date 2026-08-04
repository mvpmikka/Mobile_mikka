import { Injectable, NotFoundException } from '@nestjs/common';
import { FriendshipRepository } from '../repositories/friendship.repository';
import type { FriendItem, PaginatedResult } from '../types/friendship.type';

@Injectable()
export class FriendshipService {
  constructor(private readonly friendshipRepository: FriendshipRepository) {}

  async list(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FriendItem>> {
    const { items, total } = await this.friendshipRepository.findManyByUser(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async remove(userId: string, friendUserId: string): Promise<void> {
    const deleted = await this.friendshipRepository.deletePair(
      userId,
      friendUserId,
    );
    if (!deleted) {
      throw new NotFoundException('You are not friends with this user');
    }
  }
}