import type { Booking } from '../../../generated/prisma/client';

export interface BookingListResult {
  items: Booking[];
  total: number;
  page: number;
  limit: number;
}

export interface BookingStats {
  pendingCount: number;
  confirmedCount: number;
  seatedCount: number;
  completedCount: number;
  cancelledCount: number;
}
