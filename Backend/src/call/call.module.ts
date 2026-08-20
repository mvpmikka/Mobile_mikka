import { Module } from '@nestjs/common';
import { FriendshipModule } from '../friendship/friendship.module';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { CallController } from './call.controller';
import { CallGateway } from './call.gateway';
import { CallService } from './services/call.service';
import { TurnCredentialService } from './services/turn-credential.service';
import { CallRepository } from './repositories/call.repository';

@Module({
  // FriendshipModule: CallService only allows calls between friends, the
  // same gate ChatModule uses for conversations. UserModule + AuthModule:
  // CallGateway verifies a socket's JWT the same way ChatGateway/
  // NotificationGateway do.
  imports: [FriendshipModule, UserModule, AuthModule],
  controllers: [CallController],
  providers: [CallGateway, CallService, TurnCredentialService, CallRepository],
})
export class CallModule {}
