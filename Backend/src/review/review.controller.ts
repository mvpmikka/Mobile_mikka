import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { ReviewService } from './review.service';
import { createReviewSchema } from './dto/create-review.dto';
import type { CreateReviewDto } from './dto/create-review.dto';
import { updateReviewSchema } from './dto/update-review.dto';
import type { UpdateReviewDto } from './dto/update-review.dto';
import { listReviewsSchema } from './dto/list-reviews.dto';
import type { ListReviewsDto } from './dto/list-reviews.dto';

@Controller()
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @Post('places/:placeId/reviews')
  @UseGuards(JwtAuthGuard)
  create(
    @Param('placeId') placeId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createReviewSchema)) dto: CreateReviewDto,
  ) {
    return this.reviewService.create(placeId, currentUser.id, dto);
  }

  @Get('places/:placeId/reviews')
  list(
    @Param('placeId') placeId: string,
    @Query(new ZodValidationPipe(listReviewsSchema)) query: ListReviewsDto,
  ) {
    return this.reviewService.listByPlace(placeId, query.page, query.limit);
  }

  @Get('places/:placeId/rating')
  @Header('Cache-Control', 'public, max-age=60')
  getRating(@Param('placeId') placeId: string) {
    return this.reviewService.getRatingSummary(placeId);
  }

  // No guard, same as places/:placeId/reviews above — reviews have never
  // been privacy-gated in this codebase (see ReviewRepository.findManyByUser).
  @Get('users/:username/reviews')
  listByUser(
    @Param('username') username: string,
    @Query(new ZodValidationPipe(listReviewsSchema)) query: ListReviewsDto,
  ) {
    return this.reviewService.listByUser(username, query.page, query.limit);
  }

  @Patch('reviews/:id')
  @UseGuards(JwtAuthGuard)
  update(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(updateReviewSchema)) dto: UpdateReviewDto,
  ) {
    return this.reviewService.update(id, currentUser.id, dto);
  }

  // Owner can always delete their own; an ADMIN can delete anyone's
  // (moderation) — see ReviewService.remove.
  @Delete('reviews/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  remove(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.reviewService.remove(
      id,
      currentUser.id,
      currentUser.role === Role.ADMIN,
    );
  }
}
