import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PlaceRepository } from '../../place/repositories/place.repository';
import { ImageProcessingService } from '../../upload/services/image-processing.service';
import { StorageService } from '../../upload/services/storage.service';
import { VerificationRepository } from '../repositories/verification.repository';
import {
  PlaceVerificationStatus,
  Role,
} from '../../../generated/prisma/client';
import type { Place } from '../../../generated/prisma/client';
import type { AuthenticatedUser } from '../../auth/strategies/jwt.strategy';
import type {
  PendingVerificationItem,
  VerificationStatusResult,
} from '../types/verification.type';

// How long a signed "view the document" link stays valid. Short on purpose
// — see StorageService.getSignedUrl.
const SIGNED_URL_TTL_SECONDS = 300;

@Injectable()
export class VerificationService {
  constructor(
    private readonly verificationRepository: VerificationRepository,
    private readonly placeRepository: PlaceRepository,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
  ) {}

  // Unlike Order/Product/Booking (ADMIN-role-gated only, no per-place
  // ownership check — see docs/foundation.md), verification documents are
  // government-ID-grade personal data: any admin seeing any other admin's
  // passport/license would be a real privacy problem, not just a UX gap.
  // So this module deliberately checks real ownership, not just role.
  private async requireOwner(placeId: string, userId: string): Promise<Place> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
    if (place.createdById !== userId) {
      throw new ForbiddenException(
        "Only this place's owner can manage its verification document",
      );
    }
    return place;
  }

  private async requireOwnerOrReviewer(
    placeId: string,
    user: AuthenticatedUser,
  ): Promise<Place> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
    const isOwner = place.createdById === user.id;
    const isReviewer = user.role === Role.SUPER_ADMIN;
    if (!isOwner && !isReviewer) {
      throw new ForbiddenException(
        "You don't have access to this place's verification status",
      );
    }
    return place;
  }

  private docPath(placeId: string): string {
    // Stable per-place path — a resubmission overwrites the previous
    // document (upsert:true in StorageService) instead of leaving orphaned
    // files behind in the bucket.
    return `verification/${placeId}.webp`;
  }

  private async toStatusResult(place: Place): Promise<VerificationStatusResult> {
    const docUrl = place.verificationDocPath
      ? await this.storageService.getSignedUrl(
          place.verificationDocPath,
          SIGNED_URL_TTL_SECONDS,
        )
      : null;

    return {
      status: place.verificationStatus,
      docUrl,
      submittedAt: place.verificationSubmittedAt,
      reviewedAt: place.verificationReviewedAt,
      rejectReason: place.verificationRejectReason,
    };
  }

  async getStatus(
    placeId: string,
    user: AuthenticatedUser,
  ): Promise<VerificationStatusResult> {
    const place = await this.requireOwnerOrReviewer(placeId, user);
    return this.toStatusResult(place);
  }

  async submit(
    placeId: string,
    userId: string,
    buffer: Buffer,
  ): Promise<VerificationStatusResult> {
    await this.requireOwner(placeId, userId);

    const processed = await this.imageProcessingService
      .process(buffer)
      .catch(() => {
        throw new BadRequestException(
          'The uploaded file is not a valid image',
        );
      });

    const path = await this.storageService.uploadPrivate(
      this.docPath(placeId),
      processed.full,
      'image/webp',
    );

    const place = await this.verificationRepository.submit(placeId, path);
    return this.toStatusResult(place);
  }

  async review(
    placeId: string,
    status: 'APPROVED' | 'REJECTED',
    rejectReason: string | undefined,
  ): Promise<VerificationStatusResult> {
    const place = await this.placeRepository.findById(placeId);
    if (!place) {
      throw new NotFoundException('Place not found');
    }
    if (place.verificationStatus !== PlaceVerificationStatus.PENDING) {
      throw new ConflictException(
        `Verification is ${place.verificationStatus.toLowerCase()}, not pending review`,
      );
    }

    const updated = await this.verificationRepository.review(
      placeId,
      status === 'APPROVED'
        ? PlaceVerificationStatus.APPROVED
        : PlaceVerificationStatus.REJECTED,
      status === 'REJECTED' ? (rejectReason ?? null) : null,
    );
    return this.toStatusResult(updated);
  }

  listPending(): Promise<PendingVerificationItem[]> {
    return this.verificationRepository.findPending();
  }
}
