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
import { Role } from '../../generated/prisma/client';
import { createPlaceSchema } from './dto/create-place.dto';
import type { CreatePlaceDto } from './dto/create-place.dto';
import { updatePlaceSchema } from './dto/update-place.dto';
import type { UpdatePlaceDto } from './dto/update-place.dto';
import { listPlacesSchema } from './dto/list-places.dto';
import type { ListPlacesDto } from './dto/list-places.dto';

@Controller('places')
export class PlaceController {
  constructor(private readonly placeService: PlaceService) {}

  @Get()
  list(@Query(new ZodValidationPipe(listPlacesSchema)) query: ListPlacesDto) {
    return this.placeService.list(query);
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
