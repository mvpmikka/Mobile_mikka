import { Module } from '@nestjs/common';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { FriendshipModule } from '../friendship/friendship.module';
import { PrivacyModule } from '../privacy/privacy.module';
import { NotificationController } from './notification.controller';
import { NotificationGateway } from './notification.gateway';
import { NotificationService } from './services/notification.service';
import { NotificationRepository } from './repositories/notification.repository';
import { FriendRequestListener } from './listeners/friend-request.listener';
import { MessageListener } from './listeners/message.listener';
import { StoryListener } from './listeners/story.listener';

@Module({
  // UserModule + AuthModule: NotificationGateway's JWT handshake auth
  // (same reason ChatModule needs them). FriendshipModule + PrivacyModule:
  // StoryListener resolves "which friends should be notified" itself
  // (see its comment) — Friendship/Privacy have no idea Notification
  // exists; this is a one-directional dependency, same as every other
  // module that reaches into them.
  imports: [UserModule, AuthModule, FriendshipModule, PrivacyModule],
  controllers: [NotificationController],
  providers: [
    NotificationGateway,
    NotificationService,
    NotificationRepository,
    FriendRequestListener,
    MessageListener,
    StoryListener,
  ],
})
export class NotificationModule {}