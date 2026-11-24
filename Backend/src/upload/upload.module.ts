import { Module } from '@nestjs/common';
import { UploadController } from './upload.controller';
import { FilesController } from './files.controller';
import { UploadService } from './upload.service';
import { ImageProcessingService } from './services/image-processing.service';
import { StorageService } from './services/storage.service';

@Module({
  controllers: [UploadController, FilesController],
  providers: [UploadService, ImageProcessingService, StorageService],
  // Both reused by VerificationModule for private verification documents —
  // StorageService for the on-disk private area, ImageProcessingService
  // for the same sharp()-based validation/resize used on post/place photos.
  exports: [StorageService, ImageProcessingService],
})
export class UploadModule {}
