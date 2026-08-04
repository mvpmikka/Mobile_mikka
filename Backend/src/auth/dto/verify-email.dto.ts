import { z } from 'zod';

export const verifyEmailSchema = z.object({
  token: z.string().min(1, 'token is required'),
});

export type VerifyEmailDto = z.infer<typeof verifyEmailSchema>;
