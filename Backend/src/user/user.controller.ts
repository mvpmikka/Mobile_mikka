import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
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
import { UserService } from './user.service';
import { updateProfileSchema } from './dto/update-profile.dto';
import type { UpdateProfileDto } from './dto/update-profile.dto';
import { usernameAvailabilitySchema } from './dto/username-availability.dto';
import type { UsernameAvailabilityQueryDto } from './dto/username-availability.dto';
import { searchUserSchema } from './dto/search-user.dto';
import type { SearchUserQueryDto } from './dto/search-user.dto';

// Static routes (me, username-availability) must stay declared before the
// dynamic :username route below — Nest/Express matches in declaration
// order, and :username would otherwise swallow them.
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  getMe(@CurrentUser() currentUser: AuthenticatedUser) {
    return this.userService.getPrivateProfile(currentUser.id);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  async updateMe(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(updateProfileSchema)) dto: UpdateProfileDto,
  ) {
    await this.userService.updateProfile(currentUser.id, dto);
    return this.userService.getPrivateProfile(currentUser.id);
  }

  @Get('username-availability')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  async checkUsernameAvailability(
    @Query(new ZodValidationPipe(usernameAvailabilitySchema))
    query: UsernameAvailabilityQueryDto,
  ) {
    const available = await this.userService.isUsernameAvailable(
      query.username,
    );
    return { available };
  }

  // Also a static route — must stay before :username for the same
  // declaration-order reason as the routes above.
  @Get('search')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  search(
    @Query(new ZodValidationPipe(searchUserSchema)) query: SearchUserQueryDto,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.userService.search(query.q, currentUser.id);
  }

  // OptionalJwtAuthGuard: profile is public, but isFollowedByMe must
  // reflect the caller's identity when they happen to be logged in.
  @Get(':username')
  @UseGuards(OptionalJwtAuthGuard)
  getPublicProfile(
    @Param('username') username: string,
    @OptionalCurrentUser() currentUser: AuthenticatedUser | undefined,
  ) {
    return this.userService.getPublicProfile(username, currentUser?.id);
  }
}
