import { z } from 'zod';
import { usernameSchema } from '../username.schema';

export const usernameAvailabilitySchema = z.object({
  username: usernameSchema,
});

export type UsernameAvailabilityQueryDto = z.infer<
  typeof usernameAvailabilitySchema
>;
