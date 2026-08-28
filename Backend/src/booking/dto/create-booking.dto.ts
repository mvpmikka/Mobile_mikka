import { z } from 'zod';

// No physical table/floor-plan model exists yet — tableLabel is a free-text
// note entered by staff, not a foreign key (same reasoning as
// OrderItem.name/unitPrice being a snapshot, not a live catalog link).
export const createBookingSchema = z.object({
  customerName: z.string().trim().min(1, 'customerName is required').max(200),
  customerPhone: z.string().trim().min(1).max(30).optional(),
  bookingTime: z.coerce.date(),
  guests: z.coerce.number().int().positive(),
  tableLabel: z.string().trim().min(1).max(50).optional(),
  note: z.string().trim().min(1).max(1000).optional(),
});

export type CreateBookingDto = z.infer<typeof createBookingSchema>;
