import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ReviewRepository } from './repositories/review.repository';
import { PlaceRatingSummaryRepository } from './repositories/place-rating-summary.repository';
import type { CreateReviewDto } from './dto/create-review.dto';
import type { UpdateReviewDto } from './dto/update-review.dto';
import type { Prisma, Review } from '../../generated/prisma/client';
import {
  REVIEW_CREATED_EVENT,
  type ReviewCreatedEvent,
} from './events/review-created.event';

@Injectable()
export class ReviewService {
  constructor(
    private readonly reviewRepository: ReviewRepository,
    private readonly ratingSummaryRepository: PlaceRatingSummaryRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async create(placeId: string, userId: string, dto: CreateReviewDto) {
    await this.requirePlace(placeId);

    const existing = await this.reviewRepository.findByUserAndPlace(
      userId,
      placeId,
    );
    if (existing) {
      throw new ConflictException(
        'You have already reviewed this place — update your existing review instead',
      );
    }

    const review = await this.reviewRepository.create({
      place: { connect: { id: placeId } },
      user: { connect: { id: userId } },
      rating: dto.rating,
      comment: dto.comment,
    });

    this.eventEmitter.emit(REVIEW_CREATED_EVENT, {
      reviewId: review.id,
      userId,
      placeId,
    } satisfies ReviewCreatedEvent);

    return review;
  }

  async findById(id: string): Promise<Review> {
    const review = await this.reviewRepository.findById(id);
    if (!review) {
      throw new NotFoundException('Review not found');
    }
    return review;
  }

  async listByPlace(placeId: string, page: number, limit: number) {
    await this.requirePlace(placeId);
    const { items, total } = await this.reviewRepository.findManyByPlace(
      placeId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async update(id: string, userId: string, dto: UpdateReviewDto) {
    const review = await this.findById(id);
    if (review.userId !== userId) {
      throw new ForbiddenException('You can only edit your own review');
    }

    const data: Prisma.ReviewUpdateInput = {};
    if (dto.rating !== undefined) data.rating = dto.rating;
    if (dto.comment !== undefined) data.comment = dto.comment;

    return this.reviewRepository.update(id, data);
  }

  // isAdmin lets an ADMIN-role caller moderate (delete) any review via the
  // same DELETE /reviews/:id endpoint — no separate Admin-module route for
  // this, see docs/foundation.md. Ownership stays the only path otherwise.
  async remove(id: string, userId: string, isAdmin = false): Promise<void> {
    const review = await this.findById(id);
    if (review.userId !== userId && !isAdmin) {
      throw new ForbiddenException('You can only delete your own review');
    }
    await this.reviewRepository.softDelete(id);
  }

  async getRatingSummary(placeId: string) {
    await this.requirePlace(placeId);
    const summary = await this.ratingSummaryRepository.findByPlaceId(placeId);
    return {
      placeId,
      averageRating: summary?.averageRating ?? 0,
      reviewCount: summary?.reviewCount ?? 0,
    };
  }

  private async requirePlace(placeId: string): Promise<void> {
    const exists = await this.reviewRepository.placeExists(placeId);
    if (!exists) {
      throw new NotFoundException('Place not found');
    }
  }
}
