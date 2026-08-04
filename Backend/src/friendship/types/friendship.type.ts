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