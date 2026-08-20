// Emitted by FollowService.follow. Deliberately just ids — see
// check-in-created.event.ts for why the payload stays minimal.
export const FOLLOW_CREATED_EVENT = 'follow.created';

export interface FollowCreatedEvent {
  followerId: string;
  followingId: string;
}
