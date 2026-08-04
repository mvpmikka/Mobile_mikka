import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConversationRepository } from '../repositories/conversation.repository';
import { MessageRepository } from '../repositories/message.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import type { CreateConversationDto } from '../dto/create-conversation.dto';
import type { Conversation } from '../../../generated/prisma/client';
import type {
  ConversationDetail,
  ConversationListItem,
  PaginatedResult,
} from '../types/chat.type';

@Injectable()
export class ConversationService {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly messageRepository: MessageRepository,
    private readonly friendshipRepository: FriendshipRepository,
  ) {}

  // PRIVATE is get-or-create (see ConversationRepository.findExistingPrivate)
  // — starting "a new conversation" with the same friend twice always
  // returns the same thread, matching how every consumer chat app behaves.
  // GROUP always creates a new conversation. Both require the creator to
  // already be friends with everyone being added — see docs/foundation.md.
  async create(
    creatorId: string,
    dto: CreateConversationDto,
  ): Promise<ConversationDetail> {
    const participantIds = [...new Set(dto.participantIds)].filter(
      (id) => id !== creatorId,
    );

    if (dto.type === 'PRIVATE') {
      if (participantIds.length !== 1) {
        throw new BadRequestException(
          'A private conversation needs exactly one other participant',
        );
      }
      const [otherId] = participantIds;
      await this.requireFriend(creatorId, otherId);

      const existing = await this.conversationRepository.findExistingPrivate(
        creatorId,
        otherId,
      );
      const conversation =
        existing ??
        (await this.conversationRepository.createPrivate(creatorId, otherId));
      return this.toDetail(conversation);
    }

    // GROUP
    if (participantIds.length < 1) {
      throw new BadRequestException(
        'A group conversation needs at least one other participant',
      );
    }
    if (!dto.name) {
      throw new BadRequestException('A group conversation requires a name');
    }
    for (const participantId of participantIds) {
      await this.requireFriend(creatorId, participantId);
    }
    const conversation = await this.conversationRepository.createGroup(
      creatorId,
      dto.name,
      participantIds,
    );
    return this.toDetail(conversation);
  }

  async getById(id: string, userId: string): Promise<ConversationDetail> {
    const conversation = await this.requireActiveParticipant(id, userId);
    return this.toDetail(conversation);
  }

  // Unread count needs one follow-up query per conversation (see
  // MessageRepository.countUnread's comment) — bounded by page size, not
  // the full conversation count, so acceptable at V1 scale.
  async list(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<ConversationListItem>> {
    const { items, total } = await this.conversationRepository.findManyForUser(
      userId,
      page,
      limit,
    );

    const mapped = await Promise.all(
      items.map(async (conversation) => {
        const me = conversation.participants.find(
          (participant) => participant.userId === userId,
        );
        const unreadCount = await this.messageRepository.countUnread(
          conversation.id,
          me?.lastReadAt ?? null,
        );
        return {
          id: conversation.id,
          type: conversation.type,
          name: conversation.name,
          participants: conversation.participants.map((p) => p.user),
          lastMessage: conversation.lastMessage,
          unreadCount,
          updatedAt: conversation.updatedAt,
        };
      }),
    );
    return { items: mapped, total, page, limit };
  }

  async rename(
    id: string,
    userId: string,
    name: string,
  ): Promise<ConversationDetail> {
    const conversation = await this.requireActiveParticipant(id, userId);
    if (conversation.type !== 'GROUP') {
      throw new BadRequestException('Only group conversations can be renamed');
    }
    if (conversation.createdById !== userId) {
      throw new ForbiddenException('Only the group creator can rename it');
    }
    const updated = await this.conversationRepository.rename(id, name);
    return this.toDetail(updated);
  }

  async addParticipant(
    id: string,
    adderId: string,
    newUserId: string,
  ): Promise<void> {
    const conversation = await this.requireActiveParticipant(id, adderId);
    if (conversation.type !== 'GROUP') {
      throw new BadRequestException(
        'Cannot add participants to a private conversation',
      );
    }
    await this.requireFriend(adderId, newUserId);
    await this.conversationRepository.addParticipant(id, newUserId);
  }

  // Covers both "creator removes someone else" and "I leave" — same
  // underlying effect (leftAt set), gated differently: leaving yourself is
  // always allowed, removing someone else requires being the creator.
  // PRIVATE conversations don't support leaving at all — see schema comment.
  async removeParticipant(
    id: string,
    requesterId: string,
    targetUserId: string,
  ): Promise<void> {
    const conversation = await this.requireActiveParticipant(id, requesterId);
    if (conversation.type !== 'GROUP') {
      throw new BadRequestException(
        'Cannot remove participants from a private conversation',
      );
    }
    if (requesterId !== targetUserId && conversation.createdById !== requesterId) {
      throw new ForbiddenException(
        'Only the group creator can remove other participants',
      );
    }
    await this.conversationRepository.removeParticipant(id, targetUserId);
  }

  async markRead(id: string, userId: string): Promise<void> {
    await this.requireActiveParticipant(id, userId);
    await this.conversationRepository.markRead(id, userId);
  }

  private async requireFriend(userId: string, otherId: string): Promise<void> {
    if (userId === otherId) {
      throw new BadRequestException("You can't start a conversation with yourself");
    }
    const areFriends = await this.friendshipRepository.exists(userId, otherId);
    if (!areFriends) {
      throw new ForbiddenException('You can only chat with friends');
    }
  }

  private async requireActiveParticipant(
    id: string,
    userId: string,
  ): Promise<Conversation> {
    const conversation = await this.conversationRepository.findById(id);
    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }
    const isActive = await this.conversationRepository.isActiveParticipant(
      id,
      userId,
    );
    if (!isActive) {
      throw new ForbiddenException(
        'You are not a participant in this conversation',
      );
    }
    return conversation;
  }

  private async toDetail(
    conversation: Conversation,
  ): Promise<ConversationDetail> {
    const participants = await this.conversationRepository.findParticipantSummaries(
      conversation.id,
    );
    return {
      id: conversation.id,
      type: conversation.type,
      name: conversation.name,
      createdById: conversation.createdById,
      participants,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
    };
  }
}