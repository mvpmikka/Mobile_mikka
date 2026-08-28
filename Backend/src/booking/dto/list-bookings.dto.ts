import { z } from 'zod';
import { BookingStatus } from '../../../generated/prisma/client';

export const listBookingsSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().trim().min(1).max(200).optional(),
  status: z.nativeEnum(BookingStatus).optional(),
  // Filters to a single calendar day (schedule view) — matched against
  // bookingTime >= start-of-day && < start-of-next-day in the repository.
  date: z.string().trim().min(1).max(10).optional(),
});

export type ListBookingsDto = z.infer<typeof listBookingsSchema>;
