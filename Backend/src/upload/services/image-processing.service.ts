import { Injectable } from '@nestjs/common';
import sharp from 'sharp';

export interface ProcessedImage {
  full: Buffer;
  thumbnail: Buffer;
}

const FULL_MAX_DIMENSION = 1920;
const THUMBNAIL_MAX_DIMENSION = 300;

// Always converts to WebP and resizes down (never up) — per
// docs/foundation.md's mobile-performance obligations: never make a
// client download a full-resolution image to render a thumbnail.
// sharp() throwing on non-image input doubles as content validation —
// the client's declared MIME type is never trusted on its own.
@Injectable()
export class ImageProcessingService {
  async process(buffer: Buffer): Promise<ProcessedImage> {
    const [full, thumbnail] = await Promise.all([
      sharp(buffer)
        .rotate()
        .resize({
          width: FULL_MAX_DIMENSION,
          height: FULL_MAX_DIMENSION,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 82 })
        .toBuffer(),
      sharp(buffer)
        .rotate()
        .resize({
          width: THUMBNAIL_MAX_DIMENSION,
          height: THUMBNAIL_MAX_DIMENSION,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 75 })
        .toBuffer(),
    ]);

    return { full, thumbnail };
  }
}
