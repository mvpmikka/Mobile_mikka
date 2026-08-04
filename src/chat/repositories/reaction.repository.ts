import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReactionRepository {
  constructor(private readonly prisma: PrismaService) {}

  // One reaction per user per message (see MessageReaction's comment) —
  // reacting again just replaces the stored emoji instead of adding a
  // second row or erroring on the unique constraint.
  async react(messageId: string, userId: string, emoji: string): Promise<void> {
    await this.prisma.messageReaction.upsert({
      where: { messageId_userId: { messageId, userId } },
      create: {
        message: { connect: { id: messageId } },
        user: { connect: { id: userId } },
        emoji,
      },
      update: { emoji },
    });
  }

  async removeReaction(messageId: string, userId: string): Promise<void> {
    await this.prisma.messageReaction.deleteMany({
      where: { messageId, userId },
    });
  }

  // Non-personalized (no reactedByMe) — for the WebSocket broadcast, which
  // is one shared payload for every recipient. See ChatGateway.broadcastReactionUpdated.
  async getReactionSummary(
    messageId: string,
  ): Promise<{ emoji: string; count: number }[]> {
    const rows = await this.prisma.messageReaction.groupBy({
      by: ['emoji'],
      where: { messageId },
      _count: { emoji: true },
    });
    return rows.map((row) => ({ emoji: row.emoji, count: row._count.emoji }));
  }
}