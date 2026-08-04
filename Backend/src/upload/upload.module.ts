import { Module } from '@nestjs/common';
import { UploadController } from './upload.controller';
import { UploadService } from './upload.service';
import { ImageProcessingService } from './services/image-processing.service';
import { StorageService } from './services/storage.service';

@Module({
  controllers: [UploadController],
  providers: [UploadService, ImageProcessingService, StorageService],
})
export class UploadModule {}
