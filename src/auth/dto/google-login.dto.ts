import { z } from 'zod';

export const googleLoginSchema = z.object({
  idToken: z.string().min(1, 'idToken is required'),
});

export type GoogleLoginDto = z.infer<typeof googleLoginSchema>;
