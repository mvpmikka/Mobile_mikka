import { z } from 'zod';

export const resendVerificationSchema = z.object({
  email: z.string().email(),
});

export type ResendVerificationDto = z.infer<typeof resendVerificationSchema>;
