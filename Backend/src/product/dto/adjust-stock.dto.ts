import { z } from 'zod';

// Positive delta = restock, negative = manual adjustment (breakage, count
// correction, etc.) — one endpoint covers both Figma actions ("Adjust
// Stock" / "Restock"), the sign is the only difference.
export const adjustStockSchema = z.object({
  delta: z.coerce
    .number()
    .int()
    .refine((n) => n !== 0, 'delta must not be zero'),
});

export type AdjustStockDto = z.infer<typeof adjustStockSchema>;
