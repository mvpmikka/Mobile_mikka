import { z } from 'zod';

export const createPlaceSchema = z
  .object({
    name: z.string().trim().min(1, 'name is required').max(200),
    description: z.string().trim().max(2000).optional(),
    categoryId: z.string().uuid('categoryId must be a valid UUID'),
    address: z.string().trim().max(500).optional(),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
    phone: z.string().trim().max(30).optional(),
    website: z.string().trim().url().max(300).optional(),
  })
  .refine(
    (data) =>
      (data.latitude !== undefined && data.longitude !== undefined) ||
      data.address !== undefined,
    {
      message: 'Provide either latitude+longitude or an address to geocode',
      path: ['address'],
    },
  )
  .refine(
    (data) => (data.latitude === undefined) === (data.longitude === undefined),
    {
      message: 'latitude and longitude must be provided together',
      path: ['longitude'],
    },
  );

export type CreatePlaceDto = z.infer<typeof createPlaceSchema>;
