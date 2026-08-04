export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface StoryAuthorSummary {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
}

export interface StoryPlaceSummary {
  id: string;
  name: string;
}

// `viewedByMe` is computed in the service layer (a separate StoryView
// lookup for the current viewer against the batch), not stored on Story
// itself — see StoryService.
export interface StoryFeedItem {
  id: string;
  user: StoryAuthorSummary;
  text: string | null;
  imageUrl: string | null;
  place: StoryPlaceSummary | null;
  createdAt: Date;
  expiresAt: Date;
  viewedByMe: boolean;
}

export interface StoryViewerItem {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
  viewedAt: Date;
}