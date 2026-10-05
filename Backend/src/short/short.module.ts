import { Module } from '@nestjs/common';
import { FriendshipModule } from '../friendship/friendship.module';
import { ShortController } from './short.controller';
import { ShortService } from './services/short.service';
import { ShortRepository } from './repositories/short.repository';

@Module({
  imports: [FriendshipModule],
  controllers: [ShortController],
  providers: [ShortService, ShortRepository],
})
export class ShortModule {}
