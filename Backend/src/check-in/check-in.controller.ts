import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
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
import { CheckInService } from './check-in.service';
import { createCheckInSchema } from './dto/create-check-in.dto';
import type { CreateCheckInDto } from './dto/create-check-in.dto';
import { listCheckInsSchema } from './dto/list-check-ins.dto';
import type { ListCheckInsDto } from './dto/list-check-ins.dto';

@Controller()
export class CheckInController {
  constructor(private readonly checkInService: CheckInService) {}

  @Post('places/:placeId/check-ins')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  create(
    @Param('placeId') placeId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createCheckInSchema)) dto: CreateCheckInDto,
  ) {
    return this.checkInService.create(placeId, currentUser.id, dto);
  }

  // Always-available self shortcut, independent of your own privacy
  // setting (the visibility check in listForUser below exists to gate
  // *other* viewers, not yourself).
  @Get('users/me/check-ins')
  @UseGuards(JwtAuthGuard)
  listMine(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listCheckInsSchema)) query: ListCheckInsDto,
  ) {
    return this.checkInService.listMine(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  // Declared after users/me/check-ins above — Nest/Express matches by
  // declaration order, and :username would otherwise swallow "me".
  // OptionalJwtAuthGuard: PUBLIC visibility must work for an anonymous
  // caller too, so this can't require JwtAuthGuard outright.
  @Get('users/:username/check-ins')
  @UseGuards(OptionalJwtAuthGuard)
  listForUser(
    @Param('username') username: string,
    @OptionalCurrentUser() currentUser: AuthenticatedUser | undefined,
    @Query(new ZodValidationPipe(listCheckInsSchema)) query: ListCheckInsDto,
  ) {
    return this.checkInService.listForUser(
      username,
      currentUser?.id,
      query.page,
      query.limit,
    );
  }

  // Aggregate only — no who/when, so safe to expose publicly without
  // Privacy-module gating.
  @Get('places/:placeId/check-ins/count')
  @Header('Cache-Control', 'public, max-age=60')
  count(@Param('placeId') placeId: string) {
    return this.checkInService.countForPlace(placeId);
  }

  @Delete('check-ins/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  remove(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.checkInService.remove(id, currentUser.id);
  }
}
