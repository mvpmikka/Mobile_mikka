import { Role } from '../../../generated/prisma/client';

const ROLE_RANK: Record<Role, number> = {
  [Role.USER]: 0,
  [Role.ADMIN]: 1,
  [Role.SUPER_ADMIN]: 2,
};

function parseEmailList(raw: string): Set<string> {
  return new Set(
    raw
      .split(',')
      .map((email) => email.trim().toLowerCase())
      .filter((email) => email.length > 0),
  );
}

/**
 * ADMIN_EMAILS / SUPER_ADMIN_EMAILS let an operator promote accounts by
 * email via env config alone — no manual DB write or extra endpoint needed.
 * Whichever role this resolves to is only ever applied if it outranks the
 * user's current stored role (see `outranks`), so removing an email from
 * env later does not silently demote anyone.
 */
export function resolveEnvRole(
  email: string,
  adminEmailsRaw: string,
  superAdminEmailsRaw: string,
): Role {
  const normalized = email.trim().toLowerCase();
  if (parseEmailList(superAdminEmailsRaw).has(normalized)) {
    return Role.SUPER_ADMIN;
  }
  if (parseEmailList(adminEmailsRaw).has(normalized)) {
    return Role.ADMIN;
  }
  return Role.USER;
}

export function outranks(a: Role, b: Role): boolean {
  return ROLE_RANK[a] > ROLE_RANK[b];
}
