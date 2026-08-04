import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { StoryRepository } from '../repositories/story.repository';
import { StoryViewRepository } from '../repositories/story-view.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import { PrivacyService } from '../../privacy/services/privacy.service';
import {
  STORY_CREATED_EVENT,
  type StoryCreatedEvent,
} from '../events/story-created.event';
import type { CreateStoryDto } from '../dto/create-story.dto';
import type { Story } from '../../../generated/prisma/client';
import type {
  PaginatedResult,
  StoryFeedItem,
  StoryViewerItem,
} from '../types/story.type';

const STORY_LIFETIME_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class StoryService {
  constructor(
    private readonly storyRepository: StoryRepository,
    private readonly storyViewRepository: StoryViewRepository,
    private readonly friendshipRepository: FriendshipRepository,
    private readonly privacyService: PrivacyService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async create(userId: string, dto: CreateStoryDto): Promise<Story> {
    if (dto.placeId) {
      const exists = await this.storyRepository.placeExists(dto.placeId);
      if (!exists) {
        throw new NotFoundException('Place not found');
      }
    }
    const expiresAt = new Date(Date.now() + STORY_LIFETIME_MS);
    const story = await this.storyRepository.create(userId, dto, expiresAt);
    const event: StoryCreatedEvent = { storyId: story.id, authorId: userId };
    this.eventEmitter.emit(STORY_CREATED_EVENT, event);
    return story;
  }

  async remove(id: string, userId: string, isAdmin = false): Promise<void> {
    const story = await this.requireStory(id);
    if (story.userId !== userId && !isAdmin) {
      throw new ForbiddenException('You can only delete your own story');
    }
    await this.storyRepository.softDelete(id);
  }

  // My own active stories + my friends' — except any friend who has
  // explicitly set storyVisibility to PRIVATE. That's a real exclusion,
  // not just "FRIENDS visibility would allow it": PRIVATE means "only me,"
  // full stop, even to friends — see PrivacyService.filterOutPrivate.
  async getFeed(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<StoryFeedItem>> {
    const friendIds = await this.friendshipRepository.findAllFriendIds(userId);
    const privateFriendIds =
      await this.privacyService.filterOutPrivate(friendIds);
    const privateSet = new Set(privateFriendIds);
    const ownerIds = [
      userId,
      ...friendIds.filter((id) => !privateSet.has(id)),
    ];

    const { items, total } = await this.storyRepository.findManyByUsers(
      ownerIds,
      page,
      limit,
    );
    const withViews = await this.attachViewedByMe(items, userId);
    return { items: withViews, total, page, limit };
  }

  // A specific user's active stories, gated by their own storyVisibility —
  // same PrivacyService.canView pattern as CheckIn's
  // GET /users/:username/check-ins, including anonymous viewers for PUBLIC.
  async getForUser(
    username: string,
    viewerId: string | undefined,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<StoryFeedItem>> {
    const ownerId = await this.storyRepository.findUserIdByUsername(username);
    if (!ownerId) {
      throw new NotFoundException('User not found');
    }

    const { storyVisibility } = await this.privacyService.getSettings(ownerId);
    const allowed = await this.privacyService.canView(
      viewerId,
      ownerId,
      storyVisibility,
    );
    if (!allowed) {
      throw new ForbiddenException(
        "You don't have permission to view this user's stories",
      );
    }

    const { items, total } = await this.storyRepository.findManyByUser(
      ownerId,
      page,
      limit,
    );
    const withViews = viewerId
      ? await this.attachViewedByMe(items, viewerId)
      : items;
    return { items: withViews, total, page, limit };
  }

  // No-ops for the story's own owner (you don't "view" your own story) —
  // otherwise requires the same visibility permission a viewer would need
  // to see the story at all, so marking-viewed can't be used to probe the
  // existence of a story you're not allowed to see.
  async markViewed(storyId: string, viewerId: string): Promise<void> {
    const story = await this.requireStory(storyId);
    if (story.userId === viewerId) {
      return;
    }

    const { storyVisibility } = await this.privacyService.getSettings(
      story.userId,
    );
    const allowed = await this.privacyService.canView(
      viewerId,
      story.userId,
      storyVisibility,
    );
    if (!allowed) {
      throw new ForbiddenException(
        "You don't have permission to view this story",
      );
    }

    await this.storyViewRepository.markViewed(storyId, viewerId);
  }

  // Always owner-only — independent of the story's own visibility
  // setting. Visibility controls who can see the *content*; this is the
  // *audience list*, which only ever belongs to the poster. See Story
  // model's comment.
  async listViewers(
    storyId: string,
    requesterId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<StoryViewerItem>> {
    const story = await this.requireStory(storyId);
    if (story.userId !== requesterId) {
      throw new ForbiddenException(
        'You can only view your own story\'s viewers',
      );
    }
    const { items, total } = await this.storyViewRepository.findManyByStory(
      storyId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  private async requireStory(id: string): Promise<Story> {
    const story = await this.storyRepository.findById(id);
    if (!story) {
      throw new NotFoundException('Story not found');
    }
    return story;
  }

  private async attachViewedByMe(
    items: StoryFeedItem[],
    viewerId: string,
  ): Promise<StoryFeedItem[]> {
    const viewedIds = await this.storyViewRepository.findViewedStoryIds(
      viewerId,
      items.map((item) => item.id),
    );
    const viewedSet = new Set(viewedIds);
    return items.map((item) => ({
      ...item,
      viewedByMe: viewedSet.has(item.id),
    }));
  }
}