import { z } from 'zod';

export const addParticipantSchema = z.object({
  userId: z.string().uuid(),
});

export type AddParticipantDto = z.infer<typeof addParticipantSchema>;