import type { Gender, Role } from '../../../generated/prisma/client';

// Never merge this with PublicProfile — email/isEmailVerified/profileCompleted
// must only ever be reachable through GET /users/me. See docs/foundation.md.
export interface PrivateProfile {
  id: string;
  email: string;
  isEmailVerified: boolean;
  username: string | null;
  fullName: string | null;
  gender: Gender | null;
  birthDate: Date | null;
  avatarUrl: string | null;
  profileCompleted: boolean;
  role: Role;
  createdAt: Date;
}

export interface PublicProfile {
  username: string;
  fullName: string | null;
  avatarUrl: string | null;
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
