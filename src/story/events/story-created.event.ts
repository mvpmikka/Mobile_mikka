// Emitted by StoryService.create. Deliberately just the two ids — "who
// should be notified" (friends, minus anyone the author set storyVisibility
// to PRIVATE for) is a privacy-policy decision, not a Story-domain fact,
// so the listener resolves it itself via FriendshipRepository +
// PrivacyService — the same reach into Friendship that Privacy and Chat
// already have, for their own equally legitimate reasons.
export const STORY_CREATED_EVENT = 'story.created';

export interface StoryCreatedEvent {
  storyId: string;
  authorId: string;
}