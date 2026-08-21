import { Module } from '@nestjs/common';
import { PresenceModule } from '../presence/presence.module';
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
  // PresenceModule: GET /users/me/friends/activity's `online` field — see
  // PresenceService's comment for why this isn't ChatModule directly.
  // (CheckIn data for the same endpoint is read via a local Prisma query
  // in FriendshipRepository, not by importing CheckInModule: CheckInModule
  // imports PrivacyModule, which imports this module, so importing it back
  // here would be a module cycle — same module-independence reasoning as
  // every other cross-table lookup in this codebase.)
  imports: [PresenceModule],
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