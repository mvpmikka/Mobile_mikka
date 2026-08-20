import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { BadgeService } from '../services/badge.service';
import { BadgeCriteriaType } from '../../../generated/prisma/client';
import {
  CHECK_IN_CREATED_EVENT,
  type CheckInCreatedEvent,
} from '../../check-in/events/check-in-created.event';
import {
  REVIEW_CREATED_EVENT,
  type ReviewCreatedEvent,
} from '../../review/events/review-created.event';

// Triggers badge (re-)evaluation off CheckIn/Review domain events —
// distinct from notification/listeners/badge.listener.ts, which reacts to
// BADGE_EARNED_EVENT (this listener's own output) to send a notification.
@Injectable()
export class BadgeListener {
  constructor(private readonly badgeService: BadgeService) {}

  @OnEvent(CHECK_IN_CREATED_EVENT)
  async handleCheckInCreated(event: CheckInCreatedEvent): Promise<void> {
    await this.badgeService.evaluateForUser(event.userId, [
      BadgeCriteriaType.CHECKIN_CATEGORY_COUNT,
      BadgeCriteriaType.CHECKIN_REGION_DISTINCT_COUNT,
    ]);
  }

  @OnEvent(REVIEW_CREATED_EVENT)
  async handleReviewCreated(event: ReviewCreatedEvent): Promise<void> {
    await this.badgeService.evaluateForUser(event.userId, [
      BadgeCriteriaType.REVIEW_COUNT,
    ]);
  }
}
