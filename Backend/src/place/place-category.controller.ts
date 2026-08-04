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
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { PlaceCategoryService } from './services/place-category.service';
import { Role } from '../../generated/prisma/client';
import { createPlaceCategorySchema } from './dto/create-place-category.dto';
import type { CreatePlaceCategoryDto } from './dto/create-place-category.dto';
import { updatePlaceCategorySchema } from './dto/update-place-category.dto';
import type { UpdatePlaceCategoryDto } from './dto/update-place-category.dto';

// Static route ordering doesn't matter here — every sub-route is either
// bare or has exactly one :id segment, no ambiguity like /users/me vs
// /users/:username had.
@Controller('place-categories')
export class PlaceCategoryController {
  constructor(private readonly categoryService: PlaceCategoryService) {}

  // Admin-managed, changes rarely — safe to let clients/CDNs cache briefly.
  @Get()
  @Header('Cache-Control', 'public, max-age=300')
  findAll() {
    return this.categoryService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.categoryService.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  create(
    @Body(new ZodValidationPipe(createPlaceCategorySchema))
    dto: CreatePlaceCategoryDto,
  ) {
    return this.categoryService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  update(
    @Param('id') id: string,
    @Body(new ZodValidationPipe(updatePlaceCategorySchema))
    dto: UpdatePlaceCategoryDto,
  ) {
    return this.categoryService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  remove(@Param('id') id: string) {
    return this.categoryService.remove(id);
  }
}
