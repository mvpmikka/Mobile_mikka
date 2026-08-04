import { z } from 'zod';

// `name` is validated as required-for-GROUP at the service layer, not
// here — Zod's cross-field refine reads awkwardly for a "required if type
// is X" rule this simple, and the service already needs to branch on
// `type` for the friend-check/get-or-create logic anyway.
export const createConversationSchema = z.object({
  type: z.enum(['PRIVATE', 'GROUP']),
  participantIds: z.array(z.string().uuid()).min(1),
  name: z.string().trim().min(1).max(100).optional(),
});

export type CreateConversationDto = z.infer<typeof createConversationSchema>;