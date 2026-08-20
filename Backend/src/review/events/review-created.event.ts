// Emitted by ReviewService.create. Deliberately just ids — see
// check-in-created.event.ts for why the payload stays minimal.
export const REVIEW_CREATED_EVENT = 'review.created';

export interface ReviewCreatedEvent {
  reviewId: string;
  userId: string;
  placeId: string;
}
