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
import { PostService } from './services/post.service';
import { createPostSchema } from './dto/create-post.dto';
import type { CreatePostDto } from './dto/create-post.dto';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

// Static routes (users/me/memories) must stay declared before the dynamic
// users/:username/posts route — same declaration-order reasoning as
// UserController.
@Controller()
export class PostController {
  constructor(private readonly postService: PostService) {}

  @Post('posts')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  create(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createPostSchema)) dto: CreatePostDto,
  ) {
    return this.postService.create(currentUser.id, dto);
  }

  @Get('users/me/memories')
  @UseGuards(JwtAuthGuard)
  getMemories(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.postService.getMemories(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  // OptionalJwtAuthGuard: PUBLIC-visibility posts must work for an
  // anonymous caller too — same reasoning as Story's users/:username/stories.
  @Get('users/:username/posts')
  @UseGuards(OptionalJwtAuthGuard)
  getForUser(
    @Param('username') username: string,
    @OptionalCurrentUser() currentUser: AuthenticatedUser | undefined,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.postService.getForUser(
      username,
      currentUser?.id,
      query.page,
      query.limit,
    );
  }

  // Owner can always delete their own; an ADMIN can delete anyone's
  // (moderation) — same pattern as Story/Review.
  @Delete('posts/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  remove(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.postService.remove(
      id,
      currentUser.id,
      currentUser.role === Role.ADMIN,
    );
  }
}
