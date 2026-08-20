import type { ContentVisibility } from '../../../generated/prisma/client';

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface PostAuthorSummary {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
}

export interface PostPlaceSummary {
  id: string;
  name: string;
}

export interface PostImageItem {
  id: string;
  url: string;
  thumbnailUrl: string | null;
  position: number;
}

export interface PostFeedItem {
  id: string;
  user: PostAuthorSummary;
  caption: string | null;
  place: PostPlaceSummary | null;
  visibility: ContentVisibility;
  images: PostImageItem[];
  createdAt: Date;
}

// GET /users/me/memories — the owner's own expired Stories, not Posts.
// See PostRepository.findExpiredStoriesByUser for why this lives here.
export interface MemoryItem {
  id: string;
  text: string | null;
  imageUrl: string | null;
  place: PostPlaceSummary | null;
  createdAt: Date;
  expiresAt: Date;
}
