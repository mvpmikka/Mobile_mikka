import { Module } from '@nestjs/common';
import { FriendshipModule } from '../friendship/friendship.module';
import { PrivacyController } from './privacy.controller';
import { PrivacyService } from './services/privacy.service';
import { PrivacySettingsRepository } from './repositories/privacy-settings.repository';

@Module({
  imports: [FriendshipModule],
  controllers: [PrivacyController],
  providers: [PrivacyService, PrivacySettingsRepository],
  // PrivacyService is exported so content modules (CheckIn today, Story
  // later) can call canView()/getSettings() without knowing about
  // Friendship at all — see docs/foundation.md.
  exports: [PrivacyService],
})
export class PrivacyModule {}