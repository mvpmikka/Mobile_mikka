import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationService } from '../services/notification.service';
import { NotificationRepository } from '../repositories/notification.repository';
import {
  FRIEND_REQUEST_CREATED_EVENT,
  type FriendRequestCreatedEvent,
} from '../../friendship/events/friend-request-created.event';

@Injectable()
export class FriendRequestListener {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly notificationRepository: NotificationRepository,
  ) {}

  @OnEvent(FRIEND_REQUEST_CREATED_EVENT)
  async handle(event: FriendRequestCreatedEvent): Promise<void> {
    const requester = await this.notificationRepository.findUserProfile(
      event.requesterId,
    );
    const name = requester?.username ?? 'Someone';

    await this.notificationService.notify(
      event.addresseeId,
      'FRIEND_REQUEST',
      `${name} sent you a friend request`,
      { requestId: event.requestId, requesterId: event.requesterId },
    );
  }
}