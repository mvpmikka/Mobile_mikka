import { z } from 'zod';

// Partial on purpose — a client changing just one setting shouldn't have
// to resend the other. At least one field required (an empty PATCH is
// meaningless).
export const updatePrivacySettingsSchema = z
  .object({
    checkInVisibility: z.enum(['PUBLIC', 'FRIENDS', 'PRIVATE']).optional(),
  })
  .refine((data) => data.checkInVisibility !== undefined, {
    message: 'At least one of checkInVisibility is required',
  });

export type UpdatePrivacySettingsDto = z.infer<
  typeof updatePrivacySettingsSchema
>;
