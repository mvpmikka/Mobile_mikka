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
import { BlockService } from './services/block.service';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller()
@UseGuards(JwtAuthGuard)
export class BlockController {
  constructor(private readonly blockService: BlockService) {}

  // Static route before the dynamic :userId routes below — same ordering
  // reason as UserController.
  @Get('users/me/blocked-users')
  list(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.blockService.list(currentUser.id, query.page, query.limit);
  }

  @Post('users/:userId/block')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  block(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.blockService.block(currentUser.id, userId);
  }

  @Delete('users/:userId/block')
  @HttpCode(HttpStatus.NO_CONTENT)
  unblock(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.blockService.unblock(currentUser.id, userId);
  }
}