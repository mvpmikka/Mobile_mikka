import { Module } from '@nestjs/common';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';
import { ReviewRepository } from './repositories/review.repository';
import { PlaceRatingSummaryRepository } from './repositories/place-rating-summary.repository';

@Module({
  controllers: [ReviewController],
  providers: [ReviewService, ReviewRepository, PlaceRatingSummaryRepository],
})
export class ReviewModule {}
