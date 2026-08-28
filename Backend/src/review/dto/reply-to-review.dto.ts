import { z } from 'zod';

export const replyToReviewSchema = z.object({
  reply: z.string().trim().min(1, 'reply is required').max(2000),
});

export type ReplyToReviewDto = z.infer<typeof replyToReviewSchema>;
