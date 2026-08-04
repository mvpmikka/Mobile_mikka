import { Injectable } from '@nestjs/common';
import { SearchRepository } from './repositories/search.repository';
import type { SearchPlacesDto } from './dto/search-places.dto';
import type { PaginatedSearchResult } from './types/search-result.type';

@Injectable()
export class SearchService {
  constructor(private readonly searchRepository: SearchRepository) {}

  async searchPlaces(dto: SearchPlacesDto): Promise<PaginatedSearchResult> {
    const { items, total } = await this.searchRepository.searchPlaces({
      query: dto.q,
      page: dto.page,
      limit: dto.limit,
      categoryId: dto.categoryId,
      latitude: dto.lat,
      longitude: dto.lng,
      radiusMeters: dto.radiusMeters,
    });

    return { items, total, page: dto.page, limit: dto.limit };
  }
}
