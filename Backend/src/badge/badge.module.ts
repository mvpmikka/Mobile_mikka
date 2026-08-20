import { Module } from '@nestjs/common';
import { BadgeController } from './badge.controller';
import { BadgeService } from './services/badge.service';
import { BadgeRepository } from './repositories/badge.repository';
import { CheckinCategoryCountEvaluator } from './services/evaluators/checkin-category-count.evaluator';
import { CheckinRegionDistinctEvaluator } from './services/evaluators/checkin-region-distinct.evaluator';
import { ReviewCountEvaluator } from './services/evaluators/review-count.evaluator';
import { BadgeListener } from './listeners/badge.listener';

@Module({
  controllers: [BadgeController],
  providers: [
    BadgeService,
    BadgeRepository,
    CheckinCategoryCountEvaluator,
    CheckinRegionDistinctEvaluator,
    ReviewCountEvaluator,
    BadgeListener,
  ],
  exports: [BadgeRepository],
})
export class BadgeModule {}
