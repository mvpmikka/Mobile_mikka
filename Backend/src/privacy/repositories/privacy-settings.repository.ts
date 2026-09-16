import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  ContentVisibility,
  PrivacySettings,
} from '../../../generated/prisma/client';

export interface PrivacySettingsUpdate {
  checkInVisibility?: ContentVisibility;
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
}
