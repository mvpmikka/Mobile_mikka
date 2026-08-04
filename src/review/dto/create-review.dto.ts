import { z } from 'zod';

export const createReviewSchema = z.object({
  rating: z.number().int().min(1, 'rating must be between 1 and 5').max(5),
  comment: z.string().trim().max(2000).optional(),
});

export type CreateReviewDto = z.infer<typeof createReviewSchema>;
