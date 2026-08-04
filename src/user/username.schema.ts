import { z } from 'zod';

const RESERVED_USERNAMES = new Set([
  'admin',
  'support',
  'mikka',
  'api',
  'null',
  'undefined',
  'root',
  'system',
  'moderator',
]);

// Lowercase letters, numbers, underscores, dots — 3 to 30 chars, no leading/
// trailing/consecutive dots. Canonical form only; there's no separate
// display-case field (see docs/foundation.md).
export const usernameSchema = z
  .string()
  .min(3, 'Username must be at least 3 characters')
  .max(30, 'Username must be at most 30 characters')
  .regex(
    /^[a-z0-9](?:[a-z0-9_.]*[a-z0-9])?$/,
    'Username can only contain lowercase letters, numbers, underscores, and dots',
  )
  .refine(
    (value) => !value.includes('..'),
    'Username cannot contain consecutive dots',
  )
  .refine(
    (value) => !RESERVED_USERNAMES.has(value),
    'This username is reserved',
  );
