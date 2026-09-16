import { Injectable } from '@nestjs/common';
import { PrivacySettingsRepository } from '../repositories/privacy-settings.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import type { UpdatePrivacySettingsDto } from '../dto/update-privacy-settings.dto';
import type { ContentVisibility } from '../../../generated/prisma/client';

const DEFAULT_VISIBILITY: ContentVisibility = 'FRIENDS';

export interface PrivacySettingsView {
  checkInVisibility: ContentVisibility;
}

@Injectable()
export class PrivacyService {
  constructor(
    private readonly privacySettingsRepository: PrivacySettingsRepository,
    private readonly friendshipRepository: FriendshipRepository,
  ) {}

  async getSettings(userId: string): Promise<PrivacySettingsView> {
    const settings = await this.privacySettingsRepository.findByUserId(userId);
    return {
      checkInVisibility: settings?.checkInVisibility ?? DEFAULT_VISIBILITY,
    };
  }

  async updateSettings(
    userId: string,
    dto: UpdatePrivacySettingsDto,
  ): Promise<PrivacySettingsView> {
    const settings = await this.privacySettingsRepository.upsert(userId, {
      checkInVisibility: dto.checkInVisibility,
    });
    return {
      checkInVisibility: settings.checkInVisibility,
    };
  }

  // The single, reusable "can viewer see owner's content at this
  // visibility level" decision — content modules (CheckIn) call this
  // instead of each re-implementing "check friendship" themselves.
  // Generic over ContentVisibility, so any future content type reuses it
  // the same way. See docs/foundation.md.
  async canView(
    viewerId: string | undefined,
    ownerId: string,
    visibility: ContentVisibility,
  ): Promise<boolean> {
    if (viewerId === ownerId) {
      return true;
    }
    if (visibility === 'PUBLIC') {
      return true;
    }
    if (visibility === 'PRIVATE') {
      return false;
    }
    // FRIENDS
    if (!viewerId) {
      return false;
    }
    return this.friendshipRepository.exists(ownerId, viewerId);
  }
}
