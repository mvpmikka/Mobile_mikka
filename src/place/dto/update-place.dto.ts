import { z } from 'zod';
import { PlaceStatus } from '../../../generated/prisma/client';

export const updatePlaceSchema = z
  .object({
    name: z.string().trim().min(1).max(200).optional(),
    description: z.string().trim().max(2000).optional(),
    categoryId: z.string().uuid().optional(),
    address: z.string().trim().max(500).optional(),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
    phone: z.string().trim().max(30).optional(),
    website: z.string().trim().url().max(300).optional(),
    status: z.enum(PlaceStatus).optional(),
  })
  .refine(
    (data) => (data.latitude === undefined) === (data.longitude === undefined),
    {
      message: 'latitude and longitude must be provided together',
      path: ['longitude'],
    },
  );

export type UpdatePlaceDto = z.infer<typeof updatePlaceSchema>;
