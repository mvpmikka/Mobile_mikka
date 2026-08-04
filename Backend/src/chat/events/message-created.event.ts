// Emitted by MessageService.send. Unlike FriendRequestCreatedEvent/
// StoryCreatedEvent, this carries the recipient list and rendered content
// facts (text/imageUrl/placeName) rather than just ids — ChatModule
// already computed all of this a moment earlier for its own WebSocket
// broadcast (see ChatGateway.broadcastNewMessage), so re-deriving it from
// scratch in the Notification listener (which would mean importing
// ChatModule just to re-query conversation participants) would be pure
// waste. See docs/foundation.md for why this is a deliberate asymmetry,
// not an inconsistency.
export const MESSAGE_CREATED_EVENT = 'message.created';

export interface MessageCreatedEvent {
  messageId: string;
  conversationId: string;
  senderId: string;
  recipientIds: string[];
  text: string | null;
  imageUrl: string | null;
  placeId: string | null;
  placeName: string | null;
}