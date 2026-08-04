import { z } from 'zod';

export const reactToMessageSchema = z.object({
  emoji: z.string().trim().min(1).max(8),
});

export type ReactToMessageDto = z.infer<typeof reactToMessageSchema>;