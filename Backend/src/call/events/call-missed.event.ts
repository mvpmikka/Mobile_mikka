import type { CallType } from '../../../generated/prisma/client';

// Emitted by CallService.markMissed when the 45s ringing timer elapses
// with no answer — CallListener (NotificationModule) turns this into a
// MISSED_CALL notification, same one-directional event pattern as
// MESSAGE_CREATED_EVENT/FRIEND_REQUEST_CREATED_EVENT.
export const CALL_MISSED_EVENT = 'call.missed';

export interface CallMissedEvent {
  callId: string;
  callerId: string;
  calleeId: string;
  type: CallType;
}
