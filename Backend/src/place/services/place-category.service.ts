import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PlaceCategoryRepository } from '../repositories/place-category.repository';
import { PlaceRepository } from '../repositories/place.repository';
import { slugify } from '../utils/slugify';
import type { CreatePlaceCategoryDto } from '../dto/create-place-category.dto';
import type { UpdatePlaceCategoryDto } from '../dto/update-place-category.dto';
import type { PlaceCategory } from '../../../generated/prisma/client';

@Injectable()
export class PlaceCategoryService {
  constructor(
    private readonly categoryRepository: PlaceCategoryRepository,
    private readonly placeRepository: PlaceRepository,
  ) {}

  findAll(): Promise<PlaceCategory[]> {
    return this.categoryRepository.findAll();
  }

  async findById(id: string): Promise<PlaceCategory> {
    const category = await this.categoryRepository.findById(id);
    if (!category) {
      throw new NotFoundException('Place category not found');
    }
    return category;
  }

  async create(dto: CreatePlaceCategoryDto): Promise<PlaceCategory> {
    const slug = slugify(dto.name);

    const [nameTaken, slugTaken] = await Promise.all([
      this.categoryRepository.findByNameCaseInsensitive(dto.name),
      this.categoryRepository.findBySlug(slug),
    ]);
    if (nameTaken || slugTaken) {
      throw new ConflictException('A category with this name already exists');
    }

    return this.categoryRepository.create({ name: dto.name, slug });
  }

  async update(
    id: string,
    dto: UpdatePlaceCategoryDto,
  ): Promise<PlaceCategory> {
    await this.findById(id);

    const data: { name?: string; slug?: string } = {};
    if (dto.name !== undefined) {
      const slug = slugify(dto.name);
      const [nameTaken, slugTaken] = await Promise.all([
        this.categoryRepository.findByNameCaseInsensitive(dto.name),
        this.categoryRepository.findBySlug(slug),
      ]);
      if (
        (nameTaken && nameTaken.id !== id) ||
        (slugTaken && slugTaken.id !== id)
      ) {
        throw new ConflictException('A category with this name already exists');
      }
      data.name = dto.name;
      data.slug = slug;
    }

    return this.categoryRepository.update(id, data);
  }

  async remove(id: string): Promise<void> {
    await this.findById(id);

    const placeCount = await this.placeRepository.countByCategory(id);
    if (placeCount > 0) {
      throw new ConflictException(
        'Cannot delete a category that still has places assigned to it',
      );
    }

    await this.categoryRepository.softDelete(id);
  }
}
