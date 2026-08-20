// Emitted by BadgeService.evaluateForUser when a threshold is newly met.
// Deliberately minimal — NotificationModule's badge.listener resolves the
// definition's name itself via BadgeRepository, the same reach-in-and-look-up
// pattern as Story/Follow listeners use, rather than this event carrying
// render-ready data.
export const BADGE_EARNED_EVENT = 'badge.earned';

export interface BadgeEarnedEvent {
  userId: string;
  badgeDefinitionId: string;
  badgeCode: string;
}
