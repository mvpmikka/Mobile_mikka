import { z } from 'zod';

export const searchUserSchema = z.object({
  q: z.string().trim().min(2).max(50),
});

export type SearchUserQueryDto = z.infer<typeof searchUserSchema>;
