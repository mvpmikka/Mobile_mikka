import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationService } from '../services/notification.service';
import { NotificationRepository } from '../repositories/notification.repository';
import {
  FOLLOW_CREATED_EVENT,
  type FollowCreatedEvent,
} from '../../follow/events/follow-created.event';

@Injectable()
export class FollowListener {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly notificationRepository: NotificationRepository,
  ) {}

  @OnEvent(FOLLOW_CREATED_EVENT)
  async handle(event: FollowCreatedEvent): Promise<void> {
    const follower = await this.notificationRepository.findUserProfile(
      event.followerId,
    );
    const name = follower?.username ?? 'Someone';

    await this.notificationService.notify(
      event.followingId,
      'FOLLOW',
      `${name} started following you`,
      { followerId: event.followerId },
    );
  }
}
