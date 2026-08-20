import { Injectable } from '@nestjs/common';
import { BadgeCriteriaType } from '../../../../generated/prisma/client';
import { BadgeRepository } from '../../repositories/badge.repository';
import type { BadgeDefinition } from '../../../../generated/prisma/client';

@Injectable()
export class CheckinCategoryCountEvaluator {
  readonly criteriaType = BadgeCriteriaType.CHECKIN_CATEGORY_COUNT;

  constructor(private readonly badgeRepository: BadgeRepository) {}

  async isSatisfied(
    userId: string,
    definition: BadgeDefinition,
  ): Promise<boolean> {
    const params = definition.criteriaParams as {
      categorySlugs?: string[];
    } | null;
    const categorySlugs = params?.categorySlugs ?? [];
    if (categorySlugs.length === 0) return false;

    const count = await this.badgeRepository.countCheckInsByCategorySlugs(
      userId,
      categorySlugs,
    );
    return count >= definition.threshold;
  }
}
