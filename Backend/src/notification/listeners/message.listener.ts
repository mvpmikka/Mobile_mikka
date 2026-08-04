import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationService } from '../services/notification.service';
import { NotificationRepository } from '../repositories/notification.repository';
import {
  MESSAGE_CREATED_EVENT,
  type MessageCreatedEvent,
} from '../../chat/events/message-created.event';

const TEXT_PREVIEW_MAX_LENGTH = 80;

@Injectable()
export class MessageListener {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly notificationRepository: NotificationRepository,
  ) {}

  @OnEvent(MESSAGE_CREATED_EVENT)
  async handle(event: MessageCreatedEvent): Promise<void> {
    const sender = await this.notificationRepository.findUserProfile(
      event.senderId,
    );
    const name = sender?.username ?? 'Someone';
    const body = this.buildBody(name, event);
    const data = {
      conversationId: event.conversationId,
      messageId: event.messageId,
    };

    for (const recipientId of event.recipientIds) {
      await this.notificationService.notify(
        recipientId,
        'NEW_MESSAGE',
        body,
        data,
      );
    }
  }

  // "Place Shares" (CLAUDE.md's Notification feature list) isn't a
  // separate trigger — it's this same new-message event, worded
  // differently when the message carries a placeId. See
  // docs/foundation.md.
  private buildBody(name: string, event: MessageCreatedEvent): string {
    if (event.placeId) {
      return `${name} shared a place with you: ${event.placeName}`;
    }
    if (event.imageUrl) {
      return `${name} sent you an image`;
    }
    const text = event.text ?? '';
    const preview =
      text.length > TEXT_PREVIEW_MAX_LENGTH
        ? `${text.slice(0, TEXT_PREVIEW_MAX_LENGTH)}…`
        : text;
    return `${name}: ${preview}`;
  }
}