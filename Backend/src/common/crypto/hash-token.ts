import { createHash } from 'node:crypto';

// Shared by refresh tokens and verification tokens: both are opaque random
// strings stored hashed, never in plaintext — same principle as passwords.
export function hashToken(rawToken: string): string {
  return createHash('sha256').update(rawToken).digest('hex');
}
