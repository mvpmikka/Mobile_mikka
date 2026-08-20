import { Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BadgeRepository } from '../repositories/badge.repository';
import { CheckinCategoryCountEvaluator } from './evaluators/checkin-category-count.evaluator';
import { CheckinRegionDistinctEvaluator } from './evaluators/checkin-region-distinct.evaluator';
import { ReviewCountEvaluator } from './evaluators/review-count.evaluator';
import {
  BADGE_EARNED_EVENT,
  type BadgeEarnedEvent,
} from '../events/badge-earned.event';
import type {
  BadgeCriteriaType,
  BadgeDefinition,
} from '../../../generated/prisma/client';
import type { UserBadgeItem } from '../types/badge.type';

interface BadgeEvaluator {
  readonly criteriaType: BadgeCriteriaType;
  isSatisfied(userId: string, definition: BadgeDefinition): Promise<boolean>;
}

@Injectable()
export class BadgeService {
  private readonly evaluators: Map<BadgeCriteriaType, BadgeEvaluator>;

  constructor(
    private readonly badgeRepository: BadgeRepository,
    private readonly eventEmitter: EventEmitter2,
    checkinCategoryCountEvaluator: CheckinCategoryCountEvaluator,
    checkinRegionDistinctEvaluator: CheckinRegionDistinctEvaluator,
    reviewCountEvaluator: ReviewCountEvaluator,
  ) {
    this.evaluators = new Map<BadgeCriteriaType, BadgeEvaluator>([
      [
        checkinCategoryCountEvaluator.criteriaType,
        checkinCategoryCountEvaluator,
      ],
      [
        checkinRegionDistinctEvaluator.criteriaType,
        checkinRegionDistinctEvaluator,
      ],
      [reviewCountEvaluator.criteriaType, reviewCountEvaluator],
    ]);
  }

  // Called by BadgeListener in response to CHECK_IN_CREATED_EVENT /
  // REVIEW_CREATED_EVENT — only the criteria types relevant to whichever
  // event fired are passed in, so e.g. a new review never re-checks
  // check-in-based badges.
  async evaluateForUser(
    userId: string,
    criteriaTypes: BadgeCriteriaType[],
  ): Promise<void> {
    const definitions =
      await this.badgeRepository.findDefinitionsByCriteriaTypes(
        criteriaTypes,
      );
    if (definitions.length === 0) return;

    const earnedIds = await this.badgeRepository.findEarnedDefinitionIds(
      userId,
      definitions.map((definition) => definition.id),
    );
    const unearned = definitions.filter(
      (definition) => !earnedIds.has(definition.id),
    );

    for (const definition of unearned) {
      const evaluator = this.evaluators.get(definition.criteriaType);
      if (!evaluator) continue;

      const satisfied = await evaluator.isSatisfied(userId, definition);
      if (!satisfied) continue;

      const awarded = await this.badgeRepository.award(
        userId,
        definition.id,
      );
      if (!awarded) continue;

      this.eventEmitter.emit(BADGE_EARNED_EVENT, {
        userId,
        badgeDefinitionId: definition.id,
        badgeCode: definition.code,
      } satisfies BadgeEarnedEvent);
    }
  }

  async listForUser(username: string): Promise<UserBadgeItem[]> {
    const userId = await this.badgeRepository.findUserIdByUsername(username);
    if (!userId) {
      throw new NotFoundException('User not found');
    }
    return this.badgeRepository.findManyByUserId(userId);
  }
}
