import { z } from 'zod';
import { ContentVisibility } from '../../../generated/prisma/client';

export const createShortSchema = z.object({
  caption: z.string().trim().max(2000).optional(),
  placeId: z.string().uuid().optional(),
  visibility: z.enum(ContentVisibility).default('FRIENDS'),
  videoUrl: z.string().url(),
  thumbnailUrl: z.string().url().optional(),
});

export type CreateShortDto = z.infer<typeof createShortSchema>;
