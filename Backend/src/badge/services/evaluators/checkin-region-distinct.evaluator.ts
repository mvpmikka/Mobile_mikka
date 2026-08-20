import { Injectable } from '@nestjs/common';
import { BadgeCriteriaType } from '../../../../generated/prisma/client';
import { BadgeRepository } from '../../repositories/badge.repository';
import type { BadgeDefinition } from '../../../../generated/prisma/client';

@Injectable()
export class CheckinRegionDistinctEvaluator {
  readonly criteriaType = BadgeCriteriaType.CHECKIN_REGION_DISTINCT_COUNT;

  constructor(private readonly badgeRepository: BadgeRepository) {}

  async isSatisfied(
    userId: string,
    definition: BadgeDefinition,
  ): Promise<boolean> {
    const count =
      await this.badgeRepository.countDistinctRegionsCheckedIn(userId);
    return count >= definition.threshold;
  }
}
