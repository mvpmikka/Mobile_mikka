import { z } from 'zod';

export const updateConversationSchema = z.object({
  name: z.string().trim().min(1).max(100),
});

export type UpdateConversationDto = z.infer<typeof updateConversationSchema>;