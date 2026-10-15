import { z } from 'zod';

export const geocodeAddressSchema = z.object({
  address: z.string().trim().min(1),
});

export type GeocodeAddressDto = z.infer<typeof geocodeAddressSchema>;
