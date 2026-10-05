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
import { ShortService } from './services/short.service';
import { createShortSchema } from './dto/create-short.dto';
import type { CreateShortDto } from './dto/create-short.dto';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller('shorts')
export class ShortController {
  constructor(private readonly shortService: ShortService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  create(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createShortSchema)) dto: CreateShortDto,
  ) {
    return this.shortService.create(currentUser.id, dto);
  }

  // OptionalJwtAuthGuard: PUBLIC-visibility shorts must be viewable by an
  // anonymous caller too — same reasoning as Post's users/:username/posts.
  @Get('feed')
  @UseGuards(OptionalJwtAuthGuard)
  getFeed(
    @OptionalCurrentUser() currentUser: AuthenticatedUser | undefined,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.shortService.getFeed(currentUser?.id, query.page, query.limit);
  }

  // Owner can always delete their own; an ADMIN can delete anyone's
  // (moderation) — same pattern as Post.remove.
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  remove(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.shortService.remove(
      id,
      currentUser.id,
      currentUser.role === Role.ADMIN,
    );
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  like(@Param('id') id: string, @CurrentUser() currentUser: AuthenticatedUser) {
    return this.shortService.like(id, currentUser.id);
  }

  @Delete(':id/like')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  unlike(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.shortService.unlike(id, currentUser.id);
  }
}
