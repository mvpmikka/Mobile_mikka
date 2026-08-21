import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationService } from '../services/notification.service';
import { BadgeRepository } from '../../badge/repositories/badge.repository';
import {
  BADGE_EARNED_EVENT,
  type BadgeEarnedEvent,
} from '../../badge/events/badge-earned.event';

// Distinct from src/badge/listeners/badge.listener.ts, which listens for
// CHECK_IN_CREATED_EVENT/REVIEW_CREATED_EVENT to *evaluate and award*
// badges. This listener only reacts to the resulting BADGE_EARNED_EVENT to
// turn an already-awarded badge into a user-facing notification.
@Injectable()
export class BadgeListener {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly badgeRepository: BadgeRepository,
  ) {}

  @OnEvent(BADGE_EARNED_EVENT)
  async handle(event: BadgeEarnedEvent): Promise<void> {
    const definition = await this.badgeRepository.findDefinitionById(
      event.badgeDefinitionId,
    );
    const name = definition?.name ?? event.badgeCode;

    await this.notificationService.notify(
      event.userId,
      'BADGE_EARNED',
      `You earned the "${name}" badge`,
      {
        badgeDefinitionId: event.badgeDefinitionId,
        badgeCode: event.badgeCode,
      },
    );
  }
}
