import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { PlaceService } from './services/place.service';
import { GeocodingService } from './services/geocoding.service';
import { Role } from '../../generated/prisma/client';
import { createPlaceSchema } from './dto/create-place.dto';
import type { CreatePlaceDto } from './dto/create-place.dto';
import { updatePlaceSchema } from './dto/update-place.dto';
import type { UpdatePlaceDto } from './dto/update-place.dto';
import { listPlacesSchema } from './dto/list-places.dto';
import type { ListPlacesDto } from './dto/list-places.dto';
import { geocodeAddressSchema } from './dto/geocode-address.dto';
import type { GeocodeAddressDto } from './dto/geocode-address.dto';

@Controller('places')
export class PlaceController {
  constructor(
    private readonly placeService: PlaceService,
    private readonly geocodingService: GeocodingService,
  ) {}

  @Get()
  list(@Query(new ZodValidationPipe(listPlacesSchema)) query: ListPlacesDto) {
    return this.placeService.list(query);
  }

  @Get('mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  listMine(@CurrentUser() currentUser: AuthenticatedUser) {
    return this.placeService.listMine(currentUser.id);
  }

  // Lets the app resolve an arbitrary free-text address to coordinates (e.g.
  // the AI restaurant recommender's "yo'nalish" button) via our own Nominatim
  // wrapper, instead of calling Google Geocoding directly from the client.
  // Must stay above the ':id' route below or 'geocode' would be parsed as an id.
  @Get('geocode')
  @UseGuards(JwtAuthGuard)
  geocode(
    @Query(new ZodValidationPipe(geocodeAddressSchema)) query: GeocodeAddressDto,
  ) {
    return this.geocodingService.geocode(query.address);
  }

  @Get(':id')
  @Header('Cache-Control', 'public, max-age=60')
  findOne(@Param('id') id: string) {
    return this.placeService.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  create(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createPlaceSchema)) dto: CreatePlaceDto,
  ) {
    return this.placeService.create(dto, currentUser.id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  update(
    @Param('id') id: string,
    @Body(new ZodValidationPipe(updatePlaceSchema)) dto: UpdatePlaceDto,
  ) {
    return this.placeService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  remove(@Param('id') id: string) {
    return this.placeService.remove(id);
  }
}
