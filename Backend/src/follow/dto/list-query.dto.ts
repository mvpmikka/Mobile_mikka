import { z } from 'zod';

// Shared by followers/following list endpoints — same page/limit shape,
// same reasoning as Friendship's and Story's list-query.dto.ts.
export const listQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type ListQueryDto = z.infer<typeof listQuerySchema>;
