export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

// Minimal profile projection, same reasoning as Friendship's
// FriendProfileSummary — never the full User row.
export interface FollowProfileSummary {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
}

export interface FollowItem extends FollowProfileSummary {
  followedAt: Date;
}
