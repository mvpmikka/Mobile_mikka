import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  Conversation,
  Prisma,
} from '../../../generated/prisma/client';
import type { ChatProfileSummary, MessagePreview } from '../types/chat.type';

const profileSelect = {
  id: true,
  username: true,
  fullName: true,
  avatarUrl: true,
} as const;

const lastMessageInclude = {
  messages: {
    where: { deletedAt: null },
    orderBy: { createdAt: 'desc' as const },
    take: 1,
    include: {
      sender: { select: profileSelect },
      place: { select: { id: true, name: true } },
    },
  },
} as const;

export interface ConversationWithParticipants extends Conversation {
  participants: { userId: string; lastReadAt: Date | null; user: ChatProfileSummary }[];
  lastMessage: MessagePreview | null;
}

@Injectable()
export class ConversationRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Two active-participant EXISTS checks ANDed together — for a PRIVATE
  // conversation (always exactly 2 participants by construction) this
  // uniquely identifies the existing thread between these two users, if
  // any. See ChatService.createConversation's get-or-create.
  findExistingPrivate(
    userAId: string,
    userBId: string,
  ): Promise<Conversation | null> {
    return this.prisma.conversation.findFirst({
      where: {
        type: 'PRIVATE',
        AND: [
          { participants: { some: { userId: userAId } } },
          { participants: { some: { userId: userBId } } },
        ],
      },
    });
  }

  createPrivate(creatorId: string, otherId: string): Promise<Conversation> {
    return this.prisma.conversation.create({
      data: {
        type: 'PRIVATE',
        createdBy: { connect: { id: creatorId } },
        participants: {
          create: [
            { user: { connect: { id: creatorId } } },
            { user: { connect: { id: otherId } } },
          ],
        },
      },
    });
  }

  createGroup(
    creatorId: string,
    name: string,
    participantIds: string[],
  ): Promise<Conversation> {
    return this.prisma.conversation.create({
      data: {
        type: 'GROUP',
        name,
        createdBy: { connect: { id: creatorId } },
        participants: {
          create: [
            { user: { connect: { id: creatorId } } },
            ...participantIds.map((id) => ({ user: { connect: { id } } })),
          ],
        },
      },
    });
  }

  findById(id: string): Promise<Conversation | null> {
    return this.prisma.conversation.findUnique({ where: { id } });
  }

  async isActiveParticipant(
    conversationId: string,
    userId: string,
  ): Promise<boolean> {
    const row = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    return row !== null && row.leftAt === null;
  }

  async findParticipantSummaries(
    conversationId: string,
  ): Promise<ChatProfileSummary[]> {
    const rows = await this.prisma.conversationParticipant.findMany({
      where: { conversationId, leftAt: null },
      include: { user: { select: profileSelect } },
    });
    return rows.map((row) => row.user);
  }

  // Ids only, for the gateway's broadcast target list — not exposed via
  // any controller route directly.
  async findActiveParticipantIds(conversationId: string): Promise<string[]> {
    const rows = await this.prisma.conversationParticipant.findMany({
      where: { conversationId, leftAt: null },
      select: { userId: true },
    });
    return rows.map((row) => row.userId);
  }

  rename(id: string, name: string): Promise<Conversation> {
    return this.prisma.conversation.update({ where: { id }, data: { name } });
  }

  // Upsert — re-adding someone who previously left just clears leftAt
  // instead of erroring on the (conversationId, userId) unique constraint.
  async addParticipant(conversationId: string, userId: string): Promise<void> {
    await this.prisma.conversationParticipant.upsert({
      where: { conversationId_userId: { conversationId, userId } },
      create: {
        conversation: { connect: { id: conversationId } },
        user: { connect: { id: userId } },
      },
      update: { leftAt: null },
    });
  }

  // Soft — leftAt marks departure without deleting the row, so past
  // messages stay attributed to a real participant record. Used for both
  // "creator removes someone" and "I leave" (same effect either way).
  async removeParticipant(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    await this.prisma.conversationParticipant.updateMany({
      where: { conversationId, userId, leftAt: null },
      data: { leftAt: new Date() },
    });
  }

  async markRead(conversationId: string, userId: string): Promise<void> {
    await this.prisma.conversationParticipant.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: new Date() },
    });
  }

  touchUpdatedAt(conversationId: string): Promise<Conversation> {
    return this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });
  }

  // Conversations this user actively participates in, most recently active
  // first, each with its own active-participant list, this viewer's own
  // lastReadAt (their row is in `participants`, found by the service), and
  // a last-message preview fetched via Prisma's native take:1 nested
  // relation query — no N+1 for that part. Unread count still needs a
  // per-conversation follow-up query (see MessageRepository.countUnread) —
  // its threshold differs per conversation, doesn't fit this single query.
  async findManyForUser(
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ items: ConversationWithParticipants[]; total: number }> {
    const where: Prisma.ConversationWhereInput = {
      participants: { some: { userId, leftAt: null } },
    };
    const [rows, total] = await Promise.all([
      this.prisma.conversation.findMany({
        where,
        include: {
          participants: {
            where: { leftAt: null },
            select: {
              userId: true,
              lastReadAt: true,
              user: { select: profileSelect },
            },
          },
          ...lastMessageInclude,
        },
        orderBy: { updatedAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.conversation.count({ where }),
    ]);

    const items: ConversationWithParticipants[] = rows.map((row) => ({
      ...row,
      lastMessage: row.messages[0]
        ? {
            id: row.messages[0].id,
            sender: row.messages[0].sender,
            text: row.messages[0].text,
            imageUrl: row.messages[0].imageUrl,
            place: row.messages[0].place,
            createdAt: row.messages[0].createdAt,
          }
        : null,
    }));
    return { items, total };
  }
}