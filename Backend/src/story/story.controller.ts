import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { OptionalCurrentUser } from '../auth/decorators/optional-current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { StoryService } from './services/story.service';
import { createStorySchema } from './dto/create-story.dto';
import type { CreateStoryDto } from './dto/create-story.dto';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller()
export class StoryController {
  constructor(private readonly storyService: StoryService) {}

  @Post('stories')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  create(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createStorySchema)) dto: CreateStoryDto,
  ) {
    return this.storyService.create(currentUser.id, dto);
  }

  @Get('stories/feed')
  @UseGuards(JwtAuthGuard)
  getFeed(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.storyService.getFeed(currentUser.id, query.page, query.limit);
  }

  // OptionalJwtAuthGuard: PUBLIC visibility must work for an anonymous
  // caller too — same reasoning as CheckIn's users/:username/check-ins.
  @Get('users/:username/stories')
  @UseGuards(OptionalJwtAuthGuard)
  getForUser(
    @Param('username') username: string,
    @OptionalCurrentUser() currentUser: AuthenticatedUser | undefined,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.storyService.getForUser(
      username,
      currentUser?.id,
      query.page,
      query.limit,
    );
  }

  @Post('stories/:id/view')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  async markViewed(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ): Promise<void> {
    await this.storyService.markViewed(id, currentUser.id);
  }

  // Always owner-only — see StoryService.listViewers.
  @Get('stories/:id/viewers')
  @UseGuards(JwtAuthGuard)
  listViewers(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.storyService.listViewers(
      id,
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  // Owner can always delete their own; an ADMIN can delete anyone's
  // (moderation) — same pattern as Review.
  @Delete('stories/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  remove(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.storyService.remove(
      id,
      currentUser.id,
      currentUser.role === Role.ADMIN,
    );
  }
}