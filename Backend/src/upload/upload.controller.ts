import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UploadService } from './upload.service';

const MAX_UPLOAD_SIZE_BYTES = 10 * 1024 * 1024;
const MAX_VIDEO_UPLOAD_SIZE_BYTES = 75 * 1024 * 1024;

@Controller('uploads')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('image')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_UPLOAD_SIZE_BYTES },
      fileFilter: (_req, file, callback) => {
        // Fast-path rejection only — the client's declared MIME type is
        // never trusted as the actual validation gate. sharp() failing to
        // parse the buffer is the real check, in UploadService.
        callback(null, file.mimetype.startsWith('image/'));
      },
    }),
  )
  uploadImage(@UploadedFile() file?: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('file is required and must be an image');
    }
    return this.uploadService.uploadImage(file.buffer);
  }

  @Post('video')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_VIDEO_UPLOAD_SIZE_BYTES },
      fileFilter: (_req, file, callback) => {
        // Fast-path rejection only, same convention as uploadImage — the
        // real check is the mimetype allowlist in UploadService.uploadVideo.
        callback(null, file.mimetype.startsWith('video/'));
      },
    }),
  )
  uploadVideo(@UploadedFile() file?: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('file is required and must be a video');
    }
    return this.uploadService.uploadVideo(file.buffer, file.mimetype);
  }
}
