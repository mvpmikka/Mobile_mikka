import {
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { FriendshipService } from './services/friendship.service';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller()
@UseGuards(JwtAuthGuard)
export class FriendshipController {
  constructor(private readonly friendshipService: FriendshipService) {}

  @Get('users/me/friends')
  list(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.friendshipService.list(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  // Static route — must stay before users/me/friends/:friendUserId for
  // the same declaration-order reason as UserController's static routes.
  @Get('users/me/friends/activity')
  getActivity(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.friendshipService.getActivity(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  @Delete('users/me/friends/:friendUserId')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Param('friendUserId') friendUserId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.friendshipService.remove(currentUser.id, friendUserId);
  }
}