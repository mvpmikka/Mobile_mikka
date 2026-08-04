import { Module } from '@nestjs/common';
import { FriendshipModule } from '../friendship/friendship.module';
import { PrivacyModule } from '../privacy/privacy.module';
import { StoryController } from './story.controller';
import { StoryService } from './services/story.service';
import { StoryRepository } from './repositories/story.repository';
import { StoryViewRepository } from './repositories/story-view.repository';

@Module({
  imports: [FriendshipModule, PrivacyModule],
  controllers: [StoryController],
  providers: [StoryService, StoryRepository, StoryViewRepository],
})
export class StoryModule {}