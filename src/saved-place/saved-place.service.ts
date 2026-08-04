import { Injectable, NotFoundException } from '@nestjs/common';
import { SavedPlaceRepository } from './repositories/saved-place.repository';
import type { PaginatedResult, SavedPlaceItem } from './types/saved-place.type';

@Injectable()
export class SavedPlaceService {
  constructor(private readonly savedPlaceRepository: SavedPlaceRepository) {}

  async save(userId: string, placeId: string): Promise<void> {
    await this.requirePlace(placeId);
    await this.savedPlaceRepository.save(userId, placeId);
  }

  async unsave(userId: string, placeId: string): Promise<void> {
    await this.requirePlace(placeId);
    await this.savedPlaceRepository.unsave(userId, placeId);
  }

  async list(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<SavedPlaceItem>> {
    const { items, total } = await this.savedPlaceRepository.findManyByUser(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async countForPlace(
    placeId: string,
  ): Promise<{ placeId: string; count: number }> {
    await this.requirePlace(placeId);
    const count = await this.savedPlaceRepository.countByPlace(placeId);
    return { placeId, count };
  }

  private async requirePlace(placeId: string): Promise<void> {
    const exists = await this.savedPlaceRepository.placeExists(placeId);
    if (!exists) {
      throw new NotFoundException('Place not found');
    }
  }
}