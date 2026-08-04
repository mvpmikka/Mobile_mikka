import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  ContentVisibility,
  PrivacySettings,
} from '../../../generated/prisma/client';

export interface PrivacySettingsUpdate {
  checkInVisibility?: ContentVisibility;
  storyVisibility?: ContentVisibility;
}

@Injectable()
export class PrivacySettingsRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByUserId(userId: string): Promise<PrivacySettings | null> {
    return this.prisma.privacySettings.findUnique({ where: { userId } });
  }

  // Row is created lazily on first write — see PrivacySettings model
  // comment. Upsert rather than create/update so "no row yet" and "row
  // exists" are both handled by one statement. `updates` is partial (see
  // UpdatePrivacySettingsDto) — omitted fields use the column's @default
  // on create, or stay untouched on update.
  upsert(
    userId: string,
    updates: PrivacySettingsUpdate,
  ): Promise<PrivacySettings> {
    return this.prisma.privacySettings.upsert({
      where: { userId },
      create: { user: { connect: { id: userId } }, ...updates },
      update: { ...updates },
    });
  }

  // Given a candidate set of user ids (already known friends, or self),
  // returns the subset who explicitly set storyVisibility to PRIVATE — a
  // user with no PrivacySettings row at all defaults to FRIENDS (visible),
  // so only an existing row with PRIVATE counts. Used to exclude those
  // users from a friends feed even though they'd otherwise qualify.
  async findPrivateStoryUserIds(userIds: string[]): Promise<string[]> {
    const rows = await this.prisma.privacySettings.findMany({
      where: { userId: { in: userIds }, storyVisibility: 'PRIVATE' },
      select: { userId: true },
    });
    return rows.map((row) => row.userId);
  }
}