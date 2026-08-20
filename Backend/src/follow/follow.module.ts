import { Module } from '@nestjs/common';
import { FollowController } from './follow.controller';
import { FollowService } from './services/follow.service';
import { FollowRepository } from './repositories/follow.repository';

@Module({
  controllers: [FollowController],
  providers: [FollowService, FollowRepository],
  // FollowRepository is exported so UserModule can read followers/following
  // counts (and "does the viewer already follow this profile") for
  // GET /users/me and GET /users/:username — same one-directional reach as
  // PrivacyModule importing FriendshipModule's exported repository.
  exports: [FollowRepository],
})
export class FollowModule {}
