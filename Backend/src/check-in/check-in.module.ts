import { Module } from '@nestjs/common';
import { PrivacyModule } from '../privacy/privacy.module';
import { CheckInController } from './check-in.controller';
import { CheckInService } from './check-in.service';
import { CheckInRepository } from './repositories/check-in.repository';

@Module({
  imports: [PrivacyModule],
  controllers: [CheckInController],
  providers: [CheckInService, CheckInRepository],
})
export class CheckInModule {}
