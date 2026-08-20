import { Injectable } from '@nestjs/common';
import { BadgeCriteriaType } from '../../../../generated/prisma/client';
import { BadgeRepository } from '../../repositories/badge.repository';
import type { BadgeDefinition } from '../../../../generated/prisma/client';

@Injectable()
export class ReviewCountEvaluator {
  readonly criteriaType = BadgeCriteriaType.REVIEW_COUNT;

  constructor(private readonly badgeRepository: BadgeRepository) {}

  async isSatisfied(
    userId: string,
    definition: BadgeDefinition,
  ): Promise<boolean> {
    const count = await this.badgeRepository.countReviews(userId);
    return count >= definition.threshold;
  }
}
