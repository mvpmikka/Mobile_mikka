import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ReactionRepository } from '../repositories/reaction.repository';
import { MessageRepository } from '../repositories/message.repository';
import { ConversationRepository } from '../repositories/conversation.repository';
import { ChatGateway } from '../chat.gateway';
import type { Message } from '../../../generated/prisma/client';

@Injectable()
export class ReactionService {
  constructor(
    private readonly reactionRepository: ReactionRepository,
    private readonly messageRepository: MessageRepository,
    private readonly conversationRepository: ConversationRepository,
    private readonly chatGateway: ChatGateway,
  ) {}

  async react(messageId: string, userId: string, emoji: string): Promise<void> {
    const message = await this.requireMessageAsParticipant(messageId, userId);
    await this.reactionRepository.react(messageId, userId, emoji);
    await this.broadcastReactionUpdate(message.conversationId, messageId);
  }

  async removeReaction(messageId: string, userId: string): Promise<void> {
    const message = await this.requireMessageAsParticipant(messageId, userId);
    await this.reactionRepository.removeReaction(messageId, userId);
    await this.broadcastReactionUpdate(message.conversationId, messageId);
  }

  private async requireMessageAsParticipant(
    messageId: string,
    userId: string,
  ): Promise<Message> {
    const message = await this.messageRepository.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }
    const isActive = await this.conversationRepository.isActiveParticipant(
      message.conversationId,
      userId,
    );
    if (!isActive) {
      throw new ForbiddenException(
        'You are not a participant in this conversation',
      );
    }
    return message;
  }

  private async broadcastReactionUpdate(
    conversationId: string,
    messageId: string,
  ): Promise<void> {
    const reactions = await this.reactionRepository.getReactionSummary(messageId);
    const participantIds =
      await this.conversationRepository.findActiveParticipantIds(conversationId);
    this.chatGateway.broadcastReactionUpdated(participantIds, {
      conversationId,
      messageId,
      reactions,
    });
  }
}