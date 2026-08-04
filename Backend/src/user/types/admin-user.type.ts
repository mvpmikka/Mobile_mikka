import type { Role } from '../../../generated/prisma/client';

// A third profile projection alongside PrivateProfile/PublicProfile (see
// profile.type.ts) — wider still (email, role, isBanned), reachable only
// through AdminModule's ADMIN-gated routes. Never returned from any
// endpoint the described user themselves (or anyone else) can call.
export interface AdminUserView {
  id: string;
  email: string;
  username: string | null;
  fullName: string | null;
  role: Role;
  isBanned: boolean;
  isEmailVerified: boolean;
  createdAt: Date;
}