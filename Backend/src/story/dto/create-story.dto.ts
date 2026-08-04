import { z } from 'zod';

export const createStorySchema = z
  .object({
    text: z.string().trim().max(500).optional(),
    imageUrl: z.string().url().optional(),
    placeId: z.string().uuid().optional(),
  })
  .refine((data) => data.text || data.imageUrl || data.placeId, {
    message: 'At least one of text, imageUrl, placeId is required',
  });

export type CreateStoryDto = z.infer<typeof createStorySchema>;