import { Module } from '@nestjs/common';
import { FriendRequestController } from './friend-request.controller';
import { FriendshipController } from './friendship.controller';
import { BlockController } from './block.controller';
import { FriendRequestService } from './services/friend-request.service';
import { FriendshipService } from './services/friendship.service';
import { BlockService } from './services/block.service';
import { FriendRequestRepository } from './repositories/friend-request.repository';
import { FriendshipRepository } from './repositories/friendship.repository';
import { BlockRepository } from './repositories/block.repository';

@Module({
  controllers: [FriendRequestController, FriendshipController, BlockController],
  providers: [
    FriendRequestService,
    FriendshipService,
    BlockService,
    FriendRequestRepository,
    FriendshipRepository,
    BlockRepository,
  ],
  // FriendshipRepository is exported so PrivacyModule can check "are these
  // two friends" without duplicating that query — see PrivacyService.canView.
  exports: [FriendshipRepository],
})
export class FriendshipModule {}