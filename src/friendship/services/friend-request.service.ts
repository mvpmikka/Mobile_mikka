import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { FriendRequestRepository } from '../repositories/friend-request.repository';
import { FriendshipRepository } from '../repositories/friendship.repository';
import { BlockRepository } from '../repositories/block.repository';
import {
  FRIEND_REQUEST_CREATED_EVENT,
  type FriendRequestCreatedEvent,
} from '../events/friend-request-created.event';
import type { CreateFriendRequestDto } from '../dto/create-friend-request.dto';
import type { FriendRequest } from '../../../generated/prisma/client';
import type {
  FriendRequestItem,
  PaginatedResult,
} from '../types/friendship.type';

@Injectable()
export class FriendRequestService {
  constructor(
    private readonly friendRequestRepository: FriendRequestRepository,
    private readonly friendshipRepository: FriendshipRepository,
    private readonly blockRepository: BlockRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async create(
    requesterId: string,
    dto: CreateFriendRequestDto,
  ): Promise<FriendRequest> {
    const addresseeId = dto.addresseeUserId;
    if (requesterId === addresseeId) {
      throw new BadRequestException(
        "You can't send a friend request to yourself",
      );
    }

    const targetExists =
      await this.friendRequestRepository.userExists(addresseeId);
    if (!targetExists) {
      throw new NotFoundException('User not found');
    }

    // Generic message either way — never reveal to the sender which side
    // (if either) placed the block. See Block model's comment.
    const blocked = await this.blockRepository.existsEitherDirection(
      requesterId,
      addresseeId,
    );
    if (blocked) {
      throw new BadRequestException(
        'Unable to send a friend request to this user',
      );
    }

    const alreadyFriends = await this.friendshipRepository.exists(
      requesterId,
      addresseeId,
    );
    if (alreadyFriends) {
      throw new ConflictException('You are already friends with this user');
    }

    const reverse = await this.friendRequestRepository.findPending(
      addresseeId,
      requesterId,
    );
    if (reverse) {
      throw new ConflictException(
        'This user already sent you a friend request — accept it instead',
      );
    }

    const existing = await this.friendRequestRepository.findPending(
      requesterId,
      addresseeId,
    );
    if (existing) {
      throw new ConflictException('Friend request already sent');
    }

    const request = await this.friendRequestRepository.create(
      requesterId,
      addresseeId,
    );
    const event: FriendRequestCreatedEvent = {
      requestId: request.id,
      requesterId,
      addresseeId,
    };
    this.eventEmitter.emit(FRIEND_REQUEST_CREATED_EVENT, event);
    return request;
  }

  async listReceived(
    addresseeId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FriendRequestItem>> {
    const { items, total } = await this.friendRequestRepository.findManyReceived(
      addresseeId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async listSent(
    requesterId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<FriendRequestItem>> {
    const { items, total } = await this.friendRequestRepository.findManySent(
      requesterId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async accept(id: string, currentUserId: string): Promise<void> {
    const request = await this.requireRequest(id);
    if (request.addresseeId !== currentUserId) {
      throw new ForbiddenException('You can only accept requests sent to you');
    }
    await this.friendRequestRepository.acceptAndCreateFriendship(
      id,
      request.requesterId,
      request.addresseeId,
    );
  }

  async decline(id: string, currentUserId: string): Promise<void> {
    const request = await this.requireRequest(id);
    if (request.addresseeId !== currentUserId) {
      throw new ForbiddenException(
        'You can only decline requests sent to you',
      );
    }
    await this.friendRequestRepository.delete(id);
  }

  async cancel(id: string, currentUserId: string): Promise<void> {
    const request = await this.requireRequest(id);
    if (request.requesterId !== currentUserId) {
      throw new ForbiddenException('You can only cancel your own requests');
    }
    await this.friendRequestRepository.delete(id);
  }

  private async requireRequest(id: string): Promise<FriendRequest> {
    const request = await this.friendRequestRepository.findById(id);
    if (!request) {
      throw new NotFoundException('Friend request not found');
    }
    return request;
  }
}