import { z } from 'zod';

export const listCustomersSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().trim().min(1).max(200).optional(),
});

export type ListCustomersDto = z.infer<typeof listCustomersSchema>;
