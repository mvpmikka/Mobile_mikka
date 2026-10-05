import type { ContentVisibility } from '../../../generated/prisma/client';

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface ShortAuthorSummary {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
}

export interface ShortPlaceSummary {
  id: string;
  name: string;
}

export interface ShortFeedItem {
  id: string;
  user: ShortAuthorSummary;
  caption: string | null;
  place: ShortPlaceSummary | null;
  visibility: ContentVisibility;
  videoUrl: string;
  thumbnailUrl: string | null;
  likeCount: number;
  isLikedByMe: boolean;
  createdAt: Date;
}
