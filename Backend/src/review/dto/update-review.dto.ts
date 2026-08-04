import { z } from 'zod';

export const updateReviewSchema = z.object({
  rating: z
    .number()
    .int()
    .min(1, 'rating must be between 1 and 5')
    .max(5)
    .optional(),
  comment: z.string().trim().max(2000).optional(),
});

export type UpdateReviewDto = z.infer<typeof updateReviewSchema>;
