import { z } from 'zod';

export const createProductSchema = z.object({
  name: z.string().trim().min(1, 'name is required').max(200),
  sku: z.string().trim().min(1, 'sku is required').max(60),
  quantity: z.coerce.number().int().min(0).default(0),
  lowStockThreshold: z.coerce.number().int().min(0).default(5),
});

export type CreateProductDto = z.infer<typeof createProductSchema>;
