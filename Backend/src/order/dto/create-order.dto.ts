import { z } from 'zod';

// No live Product/price link yet (Products catalog doesn't exist) — staff
// enter each line item's name/quantity/price directly, POS-style.
export const createOrderSchema = z.object({
  customerName: z.string().trim().min(1, 'customerName is required').max(200),
  customerPhone: z.string().trim().min(1).max(30).optional(),
  items: z
    .array(
      z.object({
        name: z.string().trim().min(1, 'item name is required').max(200),
        quantity: z.coerce.number().int().positive(),
        unitPrice: z.coerce.number().int().min(0),
      }),
    )
    .min(1, 'At least one item is required'),
});

export type CreateOrderDto = z.infer<typeof createOrderSchema>;
