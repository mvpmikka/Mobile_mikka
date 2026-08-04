import type { ConversationType } from '../../../generated/prisma/client';

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface ChatProfileSummary {
  id: string;
  username: string | null;
  fullName: string | null;
  avatarUrl: string | null;
}

export interface MessagePlaceSummary {
  id: string;
  name: string;
}

// Grouped by emoji for direct UI rendering ("👍 3", highlighted if the
// current viewer is one of the reactors) rather than a raw per-user list —
// computed in the service layer from MessageReaction rows, not stored.
export interface ReactionSummary {
  emoji: string;
  count: number;
  reactedByMe: boolean;
}

// A trimmed preview of the message being replied to — never the full
// MessageItem (would recurse), just enough for the client to render a
// quote line above the reply.
export interface ReplyPreview {
  id: string;
  sender: ChatProfileSummary;
  text: string | null;
  imageUrl: string | null;
}

export interface MessageItem {
  id: string;
  conversationId: string;
  sender: ChatProfileSummary;
  text: string | null;
  imageUrl: string | null;
  place: MessagePlaceSummary | null;
  replyTo: ReplyPreview | null;
  reactions: ReactionSummary[];
  createdAt: Date;
}

// Deliberately lighter than MessageItem — no reactions/replyTo grouping,
// which matter for the message thread view, not a conversation-list row.
export interface MessagePreview {
  id: string;
  sender: ChatProfileSummary;
  text: string | null;
  imageUrl: string | null;
  place: MessagePlaceSummary | null;
  createdAt: Date;
}

export interface ConversationListItem {
  id: string;
  type: ConversationType;
  name: string | null;
  participants: ChatProfileSummary[];
  lastMessage: MessagePreview | null;
  unreadCount: number;
  updatedAt: Date;
}

export interface ConversationDetail {
  id: string;
  type: ConversationType;
  name: string | null;
  createdById: string;
  participants: ChatProfileSummary[];
  createdAt: Date;
  updatedAt: Date;
}