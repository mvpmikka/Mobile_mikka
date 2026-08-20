import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { FollowRepository } from '../repositories/follow.repository';
import {
  FOLLOW_CREATED_EVENT,
  type FollowCreatedEvent,
} from '../events/follow-created.event';
import type { FollowItem, PaginatedResult } from '../types/follow.type';

@Injectable()
export class FollowService {
  constructor(
    private readonly followRepository: FollowRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async follow(followerId: string, username: string): Promise<void> {
    const followingId =
      await this.followRepository.findUserIdByUsername(username);
    if (!followingId) {
      throw new NotFoundException('User not found');
    }
    if (followingId === followerId) {
      throw new BadRequestException("You can't follow yourself");
    }

    const alreadyFollowing = await this.followRepository.existsDirectional(
      followerId,
      followingId,
    );
    if (alreadyFollowing) {
      throw new ConflictException('You are already following this user');
    }

    await this.followRepository.create(followerId, followingId);
    this.eventEmitter.emit(FOLLOW_CREATED_EVENT, {
      followerId,
      followingId,
    } satisfies FollowCreatedEvent);
  }

  async unfollow(followerId: string, username: string): Promise<void> {
    const followingId =
      await this.followRepository.findUserIdByUsername(username);
    if (!followingId) {
      throw new NotFoundException('User not found');
    }
    const removed = await this.followRepository.remove(
      followerId,
      followingId,
    );
    if (!removed) {
      throw new NotFoundException('You are not following this user');
    }
  }

  async listFollowers(
    username: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FollowItem>> {
    const userId = await this.followRepository.findUserIdByUsername(username);
    if (!userId) {
      throw new NotFoundException('User not found');
    }
    const { items, total } = await this.followRepository.findManyFollowers(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async listFollowing(
    username: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FollowItem>> {
    const userId = await this.followRepository.findUserIdByUsername(username);
    if (!userId) {
      throw new NotFoundException('User not found');
    }
    const { items, total } = await this.followRepository.findManyFollowing(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }
}
