import { z } from 'zod';

// Shared by every paginated list endpoint in this module (feed, a user's
// stories, a story's viewers) — same page/limit shape, one schema instead
// of three near-identical copies within a single bounded context (same
// reasoning as Friendship's list-query.dto.ts).
export const listQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type ListQueryDto = z.infer<typeof listQuerySchema>;