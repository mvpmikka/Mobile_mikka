import { z } from 'zod';
import { ContentVisibility } from '../../../generated/prisma/client';

export const createPostSchema = z.object({
  caption: z.string().trim().max(2000).optional(),
  placeId: z.string().uuid().optional(),
  visibility: z.enum(ContentVisibility).default('FRIENDS'),
  images: z
    .array(
      z.object({
        url: z.string().url(),
        thumbnailUrl: z.string().url().optional(),
      }),
    )
    .min(1)
    .max(10),
});

export type CreatePostDto = z.infer<typeof createPostSchema>;
