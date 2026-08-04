import { z } from 'zod';

export const createPlaceCategorySchema = z.object({
  name: z.string().trim().min(1, 'name is required').max(50),
});

export type CreatePlaceCategoryDto = z.infer<typeof createPlaceCategorySchema>;
