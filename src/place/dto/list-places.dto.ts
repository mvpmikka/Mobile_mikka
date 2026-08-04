import { z } from 'zod';

// Fixed presets rather than a free-form radius — keeps the fallback-search
// behavior (see PlaceService.list) predictable and bounds worst-case query
// cost. 1/3/15 km per the approved design.
export const RADIUS_METERS_OPTIONS = [1_000, 3_000, 15_000] as const;

export const listPlacesSchema = z
  .object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().positive().max(100).default(20),
    categoryId: z.string().uuid().optional(),
    lat: z.coerce.number().min(-90).max(90).optional(),
    lng: z.coerce.number().min(-180).max(180).optional(),
    radiusMeters: z.coerce
      .number()
      .pipe(z.union([z.literal(1_000), z.literal(3_000), z.literal(15_000)]))
      .default(3_000),
  })
  .refine((data) => (data.lat === undefined) === (data.lng === undefined), {
    message: 'lat and lng must be provided together',
    path: ['lng'],
  });

export type ListPlacesDto = z.infer<typeof listPlacesSchema>;
