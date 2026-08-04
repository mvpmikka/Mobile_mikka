import { Controller, Get, Query } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { SearchService } from './search.service';
import { searchPlacesSchema } from './dto/search-places.dto';
import type { SearchPlacesDto } from './dto/search-places.dto';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get('places')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  searchPlaces(
    @Query(new ZodValidationPipe(searchPlacesSchema)) query: SearchPlacesDto,
  ) {
    return this.searchService.searchPlaces(query);
  }
}
