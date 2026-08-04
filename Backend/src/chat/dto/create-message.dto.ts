import { z } from 'zod';

export const createMessageSchema = z
  .object({
    text: z.string().trim().max(2000).optional(),
    imageUrl: z.string().url().optional(),
    placeId: z.string().uuid().optional(),
    replyToId: z.string().uuid().optional(),
  })
  .refine((data) => data.text || data.imageUrl || data.placeId, {
    message: 'At least one of text, imageUrl, placeId is required',
  });

export type CreateMessageDto = z.infer<typeof createMessageSchema>;