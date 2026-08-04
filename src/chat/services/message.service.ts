import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { MessageRepository } from '../repositories/message.repository';
import { ConversationRepository } from '../repositories/conversation.repository';
import { ChatGateway } from '../chat.gateway';
import {
  MESSAGE_CREATED_EVENT,
  type MessageCreatedEvent,
} from '../events/message-created.event';
import type { CreateMessageDto } from '../dto/create-message.dto';
import type { MessageItem, PaginatedResult } from '../types/chat.type';

@Injectable()
export class MessageService {
  constructor(
    private readonly messageRepository: MessageRepository,
    private readonly conversationRepository: ConversationRepository,
    private readonly chatGateway: ChatGateway,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async send(
    conversationId: string,
    senderId: string,
    dto: CreateMessageDto,
  ): Promise<MessageItem> {
    await this.requireActiveParticipant(conversationId, senderId);

    if (dto.placeId) {
      const exists = await this.messageRepository.placeExists(dto.placeId);
      if (!exists) {
        throw new NotFoundException('Place not found');
      }
    }
    if (dto.replyToId) {
      const belongs = await this.messageRepository.belongsToConversation(
        dto.replyToId,
        conversationId,
      );
      if (!belongs) {
        throw new BadRequestException(
          'replyToId must reference a message in this conversation',
        );
      }
    }

    const message = await this.messageRepository.create(
      conversationId,
      senderId,
      dto,
    );
    // Bumps the conversation's updatedAt so the sender's own conversation
    // list (sorted by updatedAt desc) reflects this send immediately.
    await this.conversationRepository.touchUpdatedAt(conversationId);

    // Safe to build with senderId as the "viewer" here specifically because
    // a just-created message has zero reactions — reactedByMe is
    // unpersonalized (empty either way), so this is fine to reuse as the
    // broadcast payload for every recipient. See ChatGateway's comment for
    // why that's NOT true for reaction updates.
    const item = await this.messageRepository.findItemById(
      message.id,
      senderId,
    );
    if (!item) {
      throw new NotFoundException('Message not found');
    }

    const participantIds =
      await this.conversationRepository.findActiveParticipantIds(conversationId);
    const recipients = participantIds.filter((id) => id !== senderId);
    this.chatGateway.broadcastNewMessage(recipients, item);

    // Carries recipients + rendered content facts, unlike
    // FriendRequestCreatedEvent/StoryCreatedEvent — see
    // message-created.event.ts for why.
    const event: MessageCreatedEvent = {
      messageId: item.id,
      conversationId,
      senderId,
      recipientIds: recipients,
      text: item.text,
      imageUrl: item.imageUrl,
      placeId: item.place?.id ?? null,
      placeName: item.place?.name ?? null,
    };
    this.eventEmitter.emit(MESSAGE_CREATED_EVENT, event);

    return item;
  }

  async list(
    conversationId: string,
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<MessageItem>> {
    await this.requireActiveParticipant(conversationId, userId);
    const { items, total } = await this.messageRepository.findManyByConversation(
      conversationId,
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async remove(id: string, userId: string, isAdmin = false): Promise<void> {
    const message = await this.messageRepository.findById(id);
    if (!message) {
      throw new NotFoundException('Message not found');
    }
    if (message.senderId !== userId && !isAdmin) {
      throw new ForbiddenException('You can only delete your own message');
    }

    await this.messageRepository.softDelete(id);

    const participantIds = await this.conversationRepository.findActiveParticipantIds(
      message.conversationId,
    );
    this.chatGateway.broadcastMessageDeleted(
      participantIds,
      message.conversationId,
      id,
    );
  }

  private async requireActiveParticipant(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    const isActive = await this.conversationRepository.isActiveParticipant(
      conversationId,
      userId,
    );
    if (!isActive) {
      throw new ForbiddenException(
        'You are not a participant in this conversation',
      );
    }
  }
}