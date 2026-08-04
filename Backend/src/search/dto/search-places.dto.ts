import { z } from 'zod';

export const searchPlacesSchema = z
  .object({
    q: z.string().trim().min(2, 'q must be at least 2 characters'),
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().positive().max(100).default(20),
    categoryId: z.string().uuid().optional(),
    lat: z.coerce.number().min(-90).max(90).optional(),
    lng: z.coerce.number().min(-180).max(180).optional(),
    radiusMeters: z.coerce.number().positive().max(50_000).default(5_000),
  })
  .refine((data) => (data.lat === undefined) === (data.lng === undefined), {
    message: 'lat and lng must be provided together',
    path: ['lng'],
  });

export type SearchPlacesDto = z.infer<typeof searchPlacesSchema>;
