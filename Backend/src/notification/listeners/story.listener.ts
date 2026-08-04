import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationService } from '../services/notification.service';
import { NotificationRepository } from '../repositories/notification.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import { PrivacyService } from '../../privacy/services/privacy.service';
import {
  STORY_CREATED_EVENT,
  type StoryCreatedEvent,
} from '../../story/events/story-created.event';

@Injectable()
export class StoryListener {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly notificationRepository: NotificationRepository,
    private readonly friendshipRepository: FriendshipRepository,
    private readonly privacyService: PrivacyService,
  ) {}

  @OnEvent(STORY_CREATED_EVENT)
  async handle(event: StoryCreatedEvent): Promise<void> {
    // A single owner's own setting — PRIVATE means literally no one else
    // should be notified, friendship notwithstanding. This is a different
    // question from Story's own filterOutPrivate (which filters a list of
    // *potential owners* from one viewer's perspective, for a feed) — here
    // there's exactly one owner (the author), so PrivacyService.getSettings
    // is the right tool, not that method.
    const { storyVisibility } = await this.privacyService.getSettings(
      event.authorId,
    );
    if (storyVisibility === 'PRIVATE') {
      return;
    }

    const author = await this.notificationRepository.findUserProfile(
      event.authorId,
    );
    const name = author?.username ?? 'Someone';
    const body = `${name} posted a new story`;
    const data = { storyId: event.storyId, authorId: event.authorId };

    const friendIds = await this.friendshipRepository.findAllFriendIds(
      event.authorId,
    );
    for (const friendId of friendIds) {
      await this.notificationService.notify(
        friendId,
        'STORY_UPDATE',
        body,
        data,
      );
    }
  }
}