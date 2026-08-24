import { z } from 'zod';

// Quantity is intentionally excluded — stock changes go through
// POST /:productId/adjust-stock so every change is a delta, not a blind
// overwrite (avoids lost updates from concurrent stock adjustments).
export const updateProductSchema = z
  .object({
    name: z.string().trim().min(1).max(200).optional(),
    sku: z.string().trim().min(1).max(60).optional(),
    lowStockThreshold: z.coerce.number().int().min(0).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export type UpdateProductDto = z.infer<typeof updateProductSchema>;
