import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { NotificationService } from './services/notification.service';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  list(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.notificationService.list(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() currentUser: AuthenticatedUser) {
    return this.notificationService.unreadCount(currentUser.id);
  }

  @Patch('read-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  async markAllRead(@CurrentUser() currentUser: AuthenticatedUser): Promise<void> {
    await this.notificationService.markAllRead(currentUser.id);
  }

  @Patch(':id/read')
  @HttpCode(HttpStatus.NO_CONTENT)
  async markRead(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ): Promise<void> {
    await this.notificationService.markRead(id, currentUser.id);
  }
}