import { z } from 'zod';

export const listSavedPlacesSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type ListSavedPlacesDto = z.infer<typeof listSavedPlacesSchema>;