import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { UserService } from './user.service';
import { updateProfileSchema } from './dto/update-profile.dto';
import type { UpdateProfileDto } from './dto/update-profile.dto';
import { usernameAvailabilitySchema } from './dto/username-availability.dto';
import type { UsernameAvailabilityQueryDto } from './dto/username-availability.dto';
import { searchUserSchema } from './dto/search-user.dto';
import type { SearchUserQueryDto } from './dto/search-user.dto';
import { toPrivateProfile } from './mappers/profile.mapper';

// Static routes (me, username-availability) must stay declared before the
// dynamic :username route below — Nest/Express matches in declaration
// order, and :username would otherwise swallow them.
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@CurrentUser() currentUser: AuthenticatedUser) {
    const user = await this.userService.findById(currentUser.id);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return toPrivateProfile(user);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  async updateMe(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(updateProfileSchema)) dto: UpdateProfileDto,
  ) {
    const user = await this.userService.updateProfile(currentUser.id, dto);
    return toPrivateProfile(user);
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

  @Get(':username')
  getPublicProfile(@Param('username') username: string) {
    return this.userService.getPublicProfile(username);
  }
}
