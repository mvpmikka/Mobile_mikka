import { z } from 'zod';
import { ProductStatus } from '../../../generated/prisma/client';

export const listProductsSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().trim().min(1).max(200).optional(),
  status: z.nativeEnum(ProductStatus).optional(),
});

export type ListProductsDto = z.infer<typeof listProductsSchema>;
