import { Injectable, NotFoundException } from '@nestjs/common';
import { PlaceRepository } from '../repositories/place.repository';
import { PlaceCategoryRepository } from '../repositories/place-category.repository';
import { GeocodingService } from './geocoding.service';
import type { CreatePlaceDto } from '../dto/create-place.dto';
import type { UpdatePlaceDto } from '../dto/update-place.dto';
import type { ListPlacesDto } from '../dto/list-places.dto';
import type { PlaceListResult } from '../types/place-list.type';
import type { Place, Prisma } from '../../../generated/prisma/client';

@Injectable()
export class PlaceService {
  constructor(
    private readonly placeRepository: PlaceRepository,
    private readonly categoryRepository: PlaceCategoryRepository,
    private readonly geocodingService: GeocodingService,
  ) {}

  async findById(id: string): Promise<Place> {
    const place = await this.placeRepository.findById(id);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
    return place;
  }

  async list(dto: ListPlacesDto): Promise<PlaceListResult> {
    if (dto.lat === undefined || dto.lng === undefined) {
      const { items, total } = await this.placeRepository.findMany({
        page: dto.page,
        limit: dto.limit,
        categoryId: dto.categoryId,
      });
      return {
        items,
        total,
        page: dto.page,
        limit: dto.limit,
        searchMode: 'none',
        requestedRadiusMeters: null,
        region: null,
      };
    }

    const near = await this.placeRepository.findNear({
      page: dto.page,
      limit: dto.limit,
      categoryId: dto.categoryId,
      latitude: dto.lat,
      longitude: dto.lng,
      radiusMeters: dto.radiusMeters,
    });
    if (near.total > 0) {
      return {
        items: near.items,
        total: near.total,
        page: dto.page,
        limit: dto.limit,
        searchMode: 'radius',
        requestedRadiusMeters: dto.radiusMeters,
        region: null,
      };
    }

    // Radius search came up empty — widen to the administrative region
    // containing the user's point, if one is seeded (see Region model's
    // placeholder-boundary caveat: this can legitimately be null today).
    const region = await this.placeRepository.findRegionContaining(
      dto.lat,
      dto.lng,
    );
    if (!region) {
      return {
        items: near.items,
        total: near.total,
        page: dto.page,
        limit: dto.limit,
        searchMode: 'radius',
        requestedRadiusMeters: dto.radiusMeters,
        region: null,
      };
    }

    const fallback = await this.placeRepository.findByRegion({
      page: dto.page,
      limit: dto.limit,
      categoryId: dto.categoryId,
      regionId: region.id,
      latitude: dto.lat,
      longitude: dto.lng,
    });
    return {
      items: fallback.items,
      total: fallback.total,
      page: dto.page,
      limit: dto.limit,
      searchMode: 'region_fallback',
      requestedRadiusMeters: dto.radiusMeters,
      region,
    };
  }

  async create(dto: CreatePlaceDto, createdById: string): Promise<Place> {
    await this.requireCategory(dto.categoryId);

    let { latitude, longitude } = dto;
    let address = dto.address;

    if (latitude === undefined || longitude === undefined) {
      const geocoded = await this.geocodingService.geocode(address!);
      latitude = geocoded.latitude;
      longitude = geocoded.longitude;
      address = address ?? geocoded.formattedAddress;
    }

    return this.placeRepository.create({
      name: dto.name,
      description: dto.description,
      category: { connect: { id: dto.categoryId } },
      address,
      latitude,
      longitude,
      phone: dto.phone,
      website: dto.website,
      createdBy: { connect: { id: createdById } },
    });
  }

  async update(id: string, dto: UpdatePlaceDto): Promise<Place> {
    await this.findById(id);
    if (dto.categoryId !== undefined) {
      await this.requireCategory(dto.categoryId);
    }

    const data: Prisma.PlaceUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.categoryId !== undefined)
      data.category = { connect: { id: dto.categoryId } };
    if (dto.address !== undefined) data.address = dto.address;
    if (dto.latitude !== undefined) data.latitude = dto.latitude;
    if (dto.longitude !== undefined) data.longitude = dto.longitude;
    if (dto.phone !== undefined) data.phone = dto.phone;
    if (dto.website !== undefined) data.website = dto.website;
    if (dto.status !== undefined) data.status = dto.status;

    return this.placeRepository.update(id, data);
  }

  async remove(id: string): Promise<void> {
    await this.findById(id);
    await this.placeRepository.softDelete(id);
  }

  private async requireCategory(categoryId: string): Promise<void> {
    const category = await this.categoryRepository.findById(categoryId);
    if (!category) {
      throw new NotFoundException('Place category not found');
    }
  }
}
