import type { Gender, Role } from '../../../generated/prisma/client';

// Never merge this with PublicProfile — email/isEmailVerified/profileCompleted
// must only ever be reachable through GET /users/me. See docs/foundation.md.
export interface PrivateProfile {
  id: string;
  email: string;
  isEmailVerified: boolean;
  username: string | null;
  fullName: string | null;
  bio: string | null;
  gender: Gender | null;
  birthDate: Date | null;
  avatarUrl: string | null;
  profileCompleted: boolean;
  role: Role;
  followersCount: number;
  followingCount: number;
  createdAt: Date;
}

export interface PublicProfile {
  id: string;
  username: string;
  fullName: string | null;
  bio: string | null;
  avatarUrl: string | null;
  followersCount: number;
  followingCount: number;
  // False for an anonymous viewer (GET /users/:username has no guard) —
  // never omitted, so the client doesn't need to special-case "unknown".
  isFollowedByMe: boolean;
  createdAt: Date;
}

// GET /users/search result row — deliberately narrower than AdminUserView
// (no email/role/isBanned): this is reachable by any authenticated user,
// not just admins.
export interface UserSearchResult {
  id: string;
  username: string;
  fullName: string | null;
  avatarUrl: string | null;
}
