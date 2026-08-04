import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CheckInRepository } from './repositories/check-in.repository';
import { PrivacyService } from '../privacy/services/privacy.service';
import type { CreateCheckInDto } from './dto/create-check-in.dto';
import type { CheckIn } from '../../generated/prisma/client';
import type {
  PaginatedResult,
  CheckInWithPlace,
  PublicCheckInItem,
} from './types/check-in.type';

@Injectable()
export class CheckInService {
  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly configService: ConfigService,
    private readonly privacyService: PrivacyService,
  ) {}

  async create(
    placeId: string,
    userId: string,
    dto: CreateCheckInDto,
  ): Promise<CheckIn> {
    const distanceMeters = await this.checkInRepository.getDistanceToPlace(
      placeId,
      dto.latitude,
      dto.longitude,
    );
    if (distanceMeters === null) {
      throw new NotFoundException('Place not found');
    }

    const maxDistance = this.configService.get<number>(
      'CHECK_IN_MAX_DISTANCE_METERS',
      200,
    );
    if (distanceMeters > maxDistance) {
      throw new BadRequestException(
        `You must be within ${maxDistance}m of the place to check in (you are ${Math.round(distanceMeters)}m away)`,
      );
    }

    const recent = await this.checkInRepository.findMostRecentByUserAndPlace(
      userId,
      placeId,
    );
    if (recent) {
      const cooldownMinutes = this.configService.get<number>(
        'CHECK_IN_COOLDOWN_MINUTES',
        15,
      );
      const cooldownEndsAt = new Date(
        recent.createdAt.getTime() + cooldownMinutes * 60 * 1000,
      );
      if (cooldownEndsAt > new Date()) {
        throw new ConflictException(
          `You can check in here again after ${cooldownEndsAt.toISOString()}`,
        );
      }
    }

    return this.checkInRepository.create({
      place: { connect: { id: placeId } },
      user: { connect: { id: userId } },
      latitude: dto.latitude,
      longitude: dto.longitude,
      distanceMeters,
    });
  }

  async listMine(
    userId: string,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<CheckInWithPlace>> {
    const { items, total } = await this.checkInRepository.findManyByUser(
      userId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  // Privacy-gated view of another user's check-ins (or your own, via
  // username instead of "me") — unlike listMine, the caller may be
  // anonymous (OptionalJwtAuthGuard), which PrivacyService.canView accounts
  // for directly (FRIENDS visibility can never be satisfied by an
  // anonymous viewer). Always returns the minimal PublicCheckInItem shape
  // (no coordinates), even when the viewer is the owner themselves — see
  // findManyByUserPublic's comment; use listMine for the full self-view.
  async listForUser(
    username: string,
    viewerId: string | undefined,
    page: number,
    limit: number,
  ): Promise<PaginatedResult<PublicCheckInItem>> {
    const ownerId = await this.checkInRepository.findUserIdByUsername(
      username,
    );
    if (!ownerId) {
      throw new NotFoundException('User not found');
    }

    const { checkInVisibility } =
      await this.privacyService.getSettings(ownerId);
    const allowed = await this.privacyService.canView(
      viewerId,
      ownerId,
      checkInVisibility,
    );
    if (!allowed) {
      throw new ForbiddenException(
        "You don't have permission to view this user's check-ins",
      );
    }

    const { items, total } = await this.checkInRepository.findManyByUserPublic(
      ownerId,
      page,
      limit,
    );
    return { items, total, page, limit };
  }

  async countForPlace(
    placeId: string,
  ): Promise<{ placeId: string; count: number }> {
    const count = await this.checkInRepository.countByPlace(placeId);
    return { placeId, count };
  }

  async remove(id: string, userId: string): Promise<void> {
    const checkIn = await this.checkInRepository.findById(id);
    if (!checkIn) {
      throw new NotFoundException('Check-in not found');
    }
    if (checkIn.userId !== userId) {
      throw new ForbiddenException('You can only delete your own check-in');
    }
    await this.checkInRepository.softDelete(id);
  }
}
