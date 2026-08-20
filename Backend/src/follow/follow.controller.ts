import {
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
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { FollowService } from './services/follow.service';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller()
export class FollowController {
  constructor(private readonly followService: FollowService) {}

  @Post('users/:username/follow')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  follow(
    @Param('username') username: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.followService.follow(currentUser.id, username);
  }

  @Delete('users/:username/follow')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  unfollow(
    @Param('username') username: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.followService.unfollow(currentUser.id, username);
  }

  // Public — same as GET /users/:username (UserController), no guard.
  @Get('users/:username/followers')
  listFollowers(
    @Param('username') username: string,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.followService.listFollowers(
      username,
      query.page,
      query.limit,
    );
  }

  @Get('users/:username/following')
  listFollowing(
    @Param('username') username: string,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.followService.listFollowing(
      username,
      query.page,
      query.limit,
    );
  }
}
