import { Module } from '@nestjs/common';
import { FollowModule } from '../follow/follow.module';
import { UserController } from './user.controller';
import { UserRepository } from './user.repository';
import { UserService } from './user.service';

@Module({
  // FollowModule: UserService reads followers/following counts (and
  // "does the viewer follow this profile") from FollowRepository to build
  // Private/PublicProfile — see FollowModule's export comment.
  imports: [FollowModule],
  controllers: [UserController],
  providers: [UserRepository, UserService],
  exports: [UserService],
})
export class UserModule {}
