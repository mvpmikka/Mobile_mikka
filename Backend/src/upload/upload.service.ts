import { BadRequestException, Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { ImageProcessingService } from './services/image-processing.service';
import { StorageService } from './services/storage.service';
import type { UploadResult } from './types/upload-result.type';

@Injectable()
export class UploadService {
  constructor(
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
  ) {}

  // Upload is intentionally stateless — no DB table of its own. It
  // processes and stores the file, then hands back URLs; whichever module
  // calls this (User avatar, Place photos later) owns storing the
  // reference on its own records. Keeps Upload a pure infrastructure
  // module, the same role Mail plays, per CLAUDE.md's module boundaries.
  async uploadImage(buffer: Buffer): Promise<UploadResult> {
    const processed = await this.imageProcessingService
      .process(buffer)
      .catch(() => {
        throw new BadRequestException('The uploaded file is not a valid image');
      });

    const id = randomUUID();
    const [url, thumbnailUrl] = await Promise.all([
      this.storageService.upload(
        `uploads/${id}.webp`,
        processed.full,
        'image/webp',
      ),
      this.storageService.upload(
        `uploads/${id}-thumb.webp`,
        processed.thumbnail,
        'image/webp',
      ),
    ]);

    return { url, thumbnailUrl };
  }
}
