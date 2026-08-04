import { z } from 'zod';

export const updatePlaceCategorySchema = z.object({
  name: z.string().trim().min(1, 'name is required').max(50).optional(),
});

export type UpdatePlaceCategoryDto = z.infer<typeof updatePlaceCategorySchema>;
