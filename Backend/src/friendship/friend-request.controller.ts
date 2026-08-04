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
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { FriendRequestService } from './services/friend-request.service';
import { createFriendRequestSchema } from './dto/create-friend-request.dto';
import type { CreateFriendRequestDto } from './dto/create-friend-request.dto';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller('friend-requests')
@UseGuards(JwtAuthGuard)
export class FriendRequestController {
  constructor(private readonly friendRequestService: FriendRequestService) {}

  @Post()
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  create(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createFriendRequestSchema))
    dto: CreateFriendRequestDto,
  ) {
    return this.friendRequestService.create(currentUser.id, dto);
  }

  // Static routes before the dynamic :id routes below — same ordering
  // reason as UserController (Nest/Express matches by declaration order).
  @Get('received')
  listReceived(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.friendRequestService.listReceived(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  @Get('sent')
  listSent(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.friendRequestService.listSent(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  @Post(':id/accept')
  accept(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.friendRequestService.accept(id, currentUser.id);
  }

  @Post(':id/decline')
  @HttpCode(HttpStatus.NO_CONTENT)
  decline(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.friendRequestService.decline(id, currentUser.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  cancel(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.friendRequestService.cancel(id, currentUser.id);
  }
}