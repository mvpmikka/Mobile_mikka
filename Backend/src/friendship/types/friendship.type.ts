export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

// Minimal profile projection reused across every list in this module —
// never the full User row (email, gender, birthDate, etc. stay behind
// GET /users/me only, per User module's PrivateProfile/PublicProfile split).
export interface FriendProfileSummary {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
}

// `user` is always "the other person" regardless of direction — the
// requester for a received-list row, the addressee for a sent-list row.
// Keeps the shape identical for both endpoints instead of branching on
// direction client-side.
export interface FriendRequestItem {
  id: string;
  createdAt: Date;
  user: FriendProfileSummary;
}

export interface FriendItem extends FriendProfileSummary {
  friendsSince: Date;
}

export interface BlockedUserItem extends FriendProfileSummary {
  blockedAt: Date;
}

// One row per user (their single most recent active check-in) — read
// locally against the `check_ins` table (see FriendshipRepository) rather
// than importing CheckInModule, per CLAUDE.md's module-independence
// principle. Used only to build FriendActivityItem below.
export interface LatestCheckInItem {
  userId: string;
  placeName: string;
  latitude: number;
  longitude: number;
  createdAt: Date;
}

// GET /users/me/friends/activity — no live GPS (see plan): lastCheckIn and
// distanceMeters are both derived from CheckIn history, not a current
// position. distanceMeters is null whenever either side has no check-in
// to compare against. online reflects PresenceService (an open chat
// socket), not a check-in at all.
export interface FriendActivityItem extends FriendProfileSummary {
  lastCheckIn: { placeName: string; createdAt: Date } | null;
  distanceMeters: number | null;
  online: boolean;
}