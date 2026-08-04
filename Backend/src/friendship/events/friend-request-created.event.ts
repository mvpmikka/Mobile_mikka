// Emitted by FriendRequestService.create — FriendshipModule has no idea
// NotificationModule exists; this event (name + payload shape) is the
// entire contract between them. Deliberately minimal (ids only) — the
// listener resolves the requester's display name itself, the same local
// profile-lookup pattern already used throughout this codebase, rather
// than this event carrying rendering-ready data. See docs/foundation.md.
export const FRIEND_REQUEST_CREATED_EVENT = 'friend-request.created';

export interface FriendRequestCreatedEvent {
  requestId: string;
  requesterId: string;
  addresseeId: string;
}