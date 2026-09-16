import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { FriendshipModule } from '../friendship/friendship.module';
import { BadgeModule } from '../badge/badge.module';
import { NotificationController } from './notification.controller';
import { NotificationGateway } from './notification.gateway';
import { NotificationService } from './services/notification.service';
import { NotificationRepository } from './repositories/notification.repository';
import { FriendRequestListener } from './listeners/friend-request.listener';
import { MessageListener } from './listeners/message.listener';
import { CallListener } from './listeners/call.listener';
import { BadgeListener } from './listeners/badge.listener';
import { FollowListener } from './listeners/follow.listener';

@Module({
  // UserModule + AuthModule: NotificationGateway's JWT handshake auth
  // (same reason ChatModule needs them). FriendshipModule: FollowListener
  // and friends-related listeners resolve "which friends should be
  // notified" — Friendship has no idea Notification exists; this is a
  // one-directional dependency, same as every other module that reaches
  // into it. BadgeModule: BadgeListener resolves the earned badge's
  // display name via BadgeRepository (exported for exactly this).
  // FollowListener needs no extra import — it only uses
  // NotificationRepository.findUserProfile, already local to this module.
  imports: [UserModule, AuthModule, FriendshipModule, BadgeModule],
  controllers: [NotificationController],
  providers: [
    NotificationGateway,
    NotificationService,
    NotificationRepository,
    FriendRequestListener,
    MessageListener,
    CallListener,
    BadgeListener,
    FollowListener,
  ],
})
export class NotificationModule {}
