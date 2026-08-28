import { z } from 'zod';
import { BookingStatus } from '../../../generated/prisma/client';

export const updateBookingStatusSchema = z.object({
  status: z.nativeEnum(BookingStatus),
});

export type UpdateBookingStatusDto = z.infer<typeof updateBookingStatusSchema>;
