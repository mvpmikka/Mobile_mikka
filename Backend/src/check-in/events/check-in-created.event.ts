// Emitted by CheckInService.create. Deliberately just ids — BadgeModule
// resolves whatever it needs (category, region) itself via its own
// repositories, the same reach-in-and-look-up pattern as Story/Friendship
// listeners use, rather than this event carrying evaluation-ready data.
export const CHECK_IN_CREATED_EVENT = 'check-in.created';

export interface CheckInCreatedEvent {
  checkInId: string;
  userId: string;
  placeId: string;
}
