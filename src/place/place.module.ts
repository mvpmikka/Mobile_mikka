import { Module } from '@nestjs/common';
import { PlaceController } from './place.controller';
import { PlaceCategoryController } from './place-category.controller';
import { PlaceService } from './services/place.service';
import { PlaceCategoryService } from './services/place-category.service';
import { GeocodingService } from './services/geocoding.service';
import { PlaceRepository } from './repositories/place.repository';
import { PlaceCategoryRepository } from './repositories/place-category.repository';

@Module({
  controllers: [PlaceController, PlaceCategoryController],
  providers: [
    PlaceService,
    PlaceCategoryService,
    GeocodingService,
    PlaceRepository,
    PlaceCategoryRepository,
  ],
})
export class PlaceModule {}
