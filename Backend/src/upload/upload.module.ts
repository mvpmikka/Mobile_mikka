import { Module } from '@nestjs/common';
import { UploadController } from './upload.controller';
import { UploadService } from './upload.service';
import { ImageProcessingService } from './services/image-processing.service';
import { StorageService } from './services/storage.service';

@Module({
  controllers: [UploadController],
  providers: [UploadService, ImageProcessingService, StorageService],
  // Both reused by VerificationModule for the private verification-document
  // bucket — StorageService for the Supabase client, ImageProcessingService
  // for the same sharp()-based validation/resize used on post/place photos.
  exports: [StorageService, ImageProcessingService],
})
export class UploadModule {}
