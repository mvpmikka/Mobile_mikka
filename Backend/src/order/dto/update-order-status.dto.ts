import { z } from 'zod';
import { OrderStatus } from '../../../generated/prisma/client';

export const updateOrderStatusSchema = z.object({
  status: z.nativeEnum(OrderStatus),
});

export type UpdateOrderStatusDto = z.infer<typeof updateOrderStatusSchema>;
