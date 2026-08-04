import {
  BadRequestException,
  ConflictException,
  NotFoundException,
  Injectable,
} from '@nestjs/common';
import { BlockRepository } from '../repositories/block.repository';
import type { BlockedUserItem, PaginatedResult } from '../types/friendship.type';

@Injectable()
export class BlockService {
  constructor(private readonly blockRepository: BlockRepository) {}

  async block(blockerId: string, blockedId: string): Promise<void> {
    if (blockerId === blockedId) {
      throw new BadRequestException("You can't block yourself");
    }

    const targetExists = await this.blockRepository.userExists(blockedId);
    if (!targetExists) {
      throw new NotFoundException('User not found');
    }

    const alreadyBlocked = await this.blockRepository.existsDirectional(
      blockerId,
      blockedId,
    );
    if (alreadyBlocked) {
      throw new ConflictException('You have already blocked this user');
    }

    await this.blockRepository.blockAndCleanup(blockerId, blockedId);
  }

  async unblock(blockerId: string, blockedId: string): Promise<void> {
    const removed = await this.blockRepository.unblock(blockerId, blockedId);
    if (!removed) {
      throw new NotFoundException('You have not blocked this user');
    }
  }

  async list(
    blockerId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<BlockedUserItem>> {
    const { items, total } = await this.blockRepository.findManyByBlocker(
      blockerId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }
}