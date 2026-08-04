import { z } from 'zod';

// Shared by every paginated list endpoint in this module (conversation
// list, message history) — same shape, one schema instead of several
// near-identical copies within a single bounded context.
export const listQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type ListQueryDto = z.infer<typeof listQuerySchema>;