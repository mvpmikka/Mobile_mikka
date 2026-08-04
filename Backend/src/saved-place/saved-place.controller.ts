import {
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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { SavedPlaceService } from './saved-place.service';
import { listSavedPlacesSchema } from './dto/list-saved-places.dto';
import type { ListSavedPlacesDto } from './dto/list-saved-places.dto';

@Controller()
export class SavedPlaceController {
  constructor(private readonly savedPlaceService: SavedPlaceService) {}

  // save/unsave are both idempotent at the service layer — see SavedPlace
  // model comment — so retrying either from the client is always safe.
  @Post('places/:placeId/saved-places')
  @UseGuards(JwtAuthGuard)
  async save(
    @Param('placeId') placeId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    await this.savedPlaceService.save(currentUser.id, placeId);
    return { placeId, saved: true };
  }

  @Delete('places/:placeId/saved-places')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  unsave(
    @Param('placeId') placeId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.savedPlaceService.unsave(currentUser.id, placeId);
  }

  // Aggregate only — no who/when, so safe to expose publicly, same
  // reasoning as CheckIn's places/:placeId/check-ins/count.
  @Get('places/:placeId/saved-places/count')
  @Header('Cache-Control', 'public, max-age=60')
  count(@Param('placeId') placeId: string) {
    return this.savedPlaceService.countForPlace(placeId);
  }

  @Get('users/me/saved-places')
  @UseGuards(JwtAuthGuard)
  list(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listSavedPlacesSchema))
    query: ListSavedPlacesDto,
  ) {
    return this.savedPlaceService.list(
      currentUser.id,
      query.page,
      query.limit,
    );
  }
}