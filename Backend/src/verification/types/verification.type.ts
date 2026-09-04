import type { PlaceVerificationStatus } from '../../../generated/prisma/client';

// What the owner (or a SUPER_ADMIN reviewing it) sees. `docUrl` is a
// short-lived signed URL, present only when a document has actually been
// submitted (status !== NONE) — never a stored/permanent value.
export interface VerificationStatusResult {
  status: PlaceVerificationStatus;
  docUrl: string | null;
  submittedAt: Date | null;
  reviewedAt: Date | null;
  rejectReason: string | null;
}

// One row in the SUPER_ADMIN review queue.
export interface PendingVerificationItem {
  placeId: string;
  placeName: string;
  submittedAt: Date | null;
}
