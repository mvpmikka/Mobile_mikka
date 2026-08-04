import { z } from 'zod';

export const createFriendRequestSchema = z.object({
  addresseeUserId: z.string().uuid(),
});

export type CreateFriendRequestDto = z.infer<typeof createFriendRequestSchema>;