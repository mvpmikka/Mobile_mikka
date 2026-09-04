import { Module } from '@nestjs/common';
import { PlaceModule } from '../place/place.module';
import { UploadModule } from '../upload/upload.module';
import { VerificationController } from './verification.controller';
import { VerificationService } from './services/verification.service';
import { VerificationRepository } from './repositories/verification.repository';

@Module({
  imports: [PlaceModule, UploadModule],
  controllers: [VerificationController],
  providers: [VerificationService, VerificationRepository],
})
export class VerificationModule {}
