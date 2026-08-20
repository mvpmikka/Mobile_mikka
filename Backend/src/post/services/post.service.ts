import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PostRepository } from '../repositories/post.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import type { CreatePostDto } from '../dto/create-post.dto';
import type { ContentVisibility, Post } from '../../../generated/prisma/client';
import type {
  MemoryItem,
  PaginatedResult,
  PostFeedItem,
} from '../types/post.type';

const ALL_VISIBILITIES: ContentVisibility[] = ['PUBLIC', 'FRIENDS', 'PRIVATE'];
const FRIEND_VISIBILITIES: ContentVisibility[] = ['PUBLIC', 'FRIENDS'];
const STRANGER_VISIBILITIES: ContentVisibility[] = ['PUBLIC'];

@Injectable()
export class PostService {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly friendshipRepository: FriendshipRepository,
  ) {}

  async create(userId: string, dto: CreatePostDto): Promise<PostFeedItem> {
    if (dto.placeId) {
      const exists = await this.postRepository.placeExists(dto.placeId);
      if (!exists) {
        throw new NotFoundException('Place not found');
      }
    }
    return this.postRepository.create(userId, dto);
  }

  async remove(id: string, userId: string, isAdmin = false): Promise<void> {
    const post = await this.requirePost(id);
    if (post.userId !== userId && !isAdmin) {
      throw new ForbiddenException('You can only delete your own post');
    }
    await this.postRepository.softDelete(id);
  }

  // A specific user's posts, filtered by each post's own visibility
  // against the viewer/owner relationship — see PostRepository.findManyByUser.
  async getForUser(
    username: string,
    viewerId: string | undefined,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<PostFeedItem>> {
    const ownerId = await this.postRepository.findUserIdByUsername(username);
    if (!ownerId) {
      throw new NotFoundException('User not found');
    }

    const allowedVisibilities = await this.resolveAllowedVisibilities(
      ownerId,
      viewerId,
    );
    const { items, total } = await this.postRepository.findManyByUser(
      ownerId,
      allowedVisibilities,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  // "Memories" — always owner-only, no visibility gating: these are
  // expired Stories nobody else can see anymore anyway.
  async getMemories(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<MemoryItem>> {
    const { items, total } = await this.postRepository.findExpiredStoriesByUser(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  private async resolveAllowedVisibilities(
    ownerId: string,
    viewerId: string | undefined,
  ): Promise<ContentVisibility[]> {
    if (viewerId === ownerId) {
      return ALL_VISIBILITIES;
    }
    const isFriend = viewerId
      ? await this.friendshipRepository.exists(ownerId, viewerId)
      : false;
    return isFriend ? FRIEND_VISIBILITIES : STRANGER_VISIBILITIES;
  }

  private async requirePost(id: string): Promise<Post> {
    const post = await this.postRepository.findById(id);
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    return post;
  }
}
