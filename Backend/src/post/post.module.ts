import { Module } from '@nestjs/common';
import { FriendshipModule } from '../friendship/friendship.module';
import { PostController } from './post.controller';
import { PostService } from './services/post.service';
import { PostRepository } from './repositories/post.repository';

@Module({
  imports: [FriendshipModule],
  controllers: [PostController],
  providers: [PostService, PostRepository],
})
export class PostModule {}
