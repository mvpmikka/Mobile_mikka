import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { Message, Prisma } from '../../../generated/prisma/client';
import type { MessageItem, ReactionSummary } from '../types/chat.type';

const profileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

const messageInclude = {
  sender: { select: profileSelect },
  place: { select: { id: true, name: true } },
  replyTo: { include: { sender: { select: profileSelect } } },
  reactions: { select: { emoji: true, userId: true } },
} as const;

type MessageRow = Prisma.MessageGetPayload<{ include: typeof messageInclude }>;

// One user can react at most once per message (see MessageReaction's
// comment) — grouping by emoji here, not at the DB level, since a
// message's reaction count is always small enough that doing it in JS is
// simpler than a GROUP BY query.
function groupReactions(
  reactions: { emoji: string; userId: string }[],
  viewerId: string,
): ReactionSummary[] {
  const byEmoji = new Map<string, ReactionSummary>();
  for (const reaction of reactions) {
    const existing = byEmoji.get(reaction.emoji);
    if (existing) {
      existing.count += 1;
      existing.reactedByMe ||= reaction.userId === viewerId;
    } else {
      byEmoji.set(reaction.emoji, {
        emoji: reaction.emoji,
        count: 1,
        reactedByMe: reaction.userId === viewerId,
      });
    }
  }
  return [...byEmoji.values()];
}

function toMessageItem(row: MessageRow, viewerId: string): MessageItem {
  return {
    id: row.id,
    conversationId: row.conversationId,
    sender: row.sender,
    text: row.text,
    imageUrl: row.imageUrl,
    place: row.place,
    replyTo: row.replyTo
      ? {
          id: row.replyTo.id,
          sender: row.replyTo.sender,
          text: row.replyTo.text,
          imageUrl: row.replyTo.imageUrl,
        }
      : null,
    reactions: groupReactions(row.reactions, viewerId),
    createdAt: row.createdAt,
  };
}

@Injectable()
export class MessageRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<Message | null> {
    return this.prisma.message.findUnique({ where: { id, deletedAt: null } });
  }

  async belongsToConversation(
    id: string,
    conversationId: string,
  ): Promise<boolean> {
    const message = await this.prisma.message.findUnique({
      where: { id, deletedAt: null },
      select: { conversationId: true },
    });
    return message?.conversationId === conversationId;
  }

  create(
    conversationId: string,
    senderId: string,
    data: { text?: string; imageUrl?: string; placeId?: string; replyToId?: string },
  ): Promise<Message> {
    return this.prisma.message.create({
      data: {
        conversation: { connect: { id: conversationId } },
        sender: { connect: { id: senderId } },
        text: data.text,
        imageUrl: data.imageUrl,
        ...(data.placeId ? { place: { connect: { id: data.placeId } } } : {}),
        ...(data.replyToId
          ? { replyTo: { connect: { id: data.replyToId } } }
          : {}),
      },
    });
  }

  // Returns the just-created message in the same shape the list endpoint
  // uses (MessageItem) — the create response and the gateway broadcast
  // payload both want this, not the raw Prisma row.
  async findItemById(id: string, viewerId: string): Promise<MessageItem | null> {
    const row = await this.prisma.message.findUnique({
      where: { id },
      include: messageInclude,
    });
    return row ? toMessageItem(row, viewerId) : null;
  }

  softDelete(id: string): Promise<Message> {
    return this.prisma.message.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async findManyByConversation(
    conversationId: string,
    viewerId: string,
    page: number,
    limit: number,
  ): Promise<{ items: MessageItem[]; total: number }> {
    const where: Prisma.MessageWhereInput = { conversationId, deletedAt: null };
    const [rows, total] = await Promise.all([
      this.prisma.message.findMany({
        where,
        include: messageInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.message.count({ where }),
    ]);
    return {
      items: rows.map((row) => toMessageItem(row, viewerId)),
      total,
    };
  }

  // Threshold differs per conversation-participant pair (each has their
  // own lastReadAt), so this can't be folded into
  // ConversationRepository.findManyForUser's single query — see that
  // method's comment.
  countUnread(conversationId: string, since: Date | null): Promise<number> {
    return this.prisma.message.count({
      where: {
        conversationId,
        deletedAt: null,
        ...(since ? { createdAt: { gt: since } } : {}),
      },
    });
  }

  // Read-only against `places` — kept minimal and local to this module
  // rather than importing PlaceModule/PlaceService, per CLAUDE.md's
  // module-independence principle (same approach Story/Review/CheckIn use).
  async placeExists(placeId: string): Promise<boolean> {
    const place = await this.prisma.place.findUnique({
      where: { id: placeId, deletedAt: null },
      select: { id: true },
    });
    return place !== null;
  }
}