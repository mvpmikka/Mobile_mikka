import { Module } from '@nestjs/common';
import { FriendshipModule } from '../friendship/friendship.module';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { PresenceModule } from '../presence/presence.module';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
import { ConversationService } from './services/conversation.service';
import { MessageService } from './services/message.service';
import { ReactionService } from './services/reaction.service';
import { ConversationRepository } from './repositories/conversation.repository';
import { MessageRepository } from './repositories/message.repository';
import { ReactionRepository } from './repositories/reaction.repository';

@Module({
  // FriendshipModule: conversation creation requires the participants to
  // be friends. UserModule + AuthModule: ChatGateway verifies a socket's
  // JWT and looks up the user directly (WebSocket connections don't go
  // through JwtAuthGuard's HTTP request/response pipeline).
  imports: [FriendshipModule, UserModule, AuthModule, PresenceModule],
  controllers: [ChatController],
  providers: [
    ChatGateway,
    ConversationService,
    MessageService,
    ReactionService,
    ConversationRepository,
    MessageRepository,
    ReactionRepository,
  ],
})
export class ChatModule {}