import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PlaceVerificationStatus } from '../../../generated/prisma/client';
import type { Place } from '../../../generated/prisma/client';
import type { PendingVerificationItem } from '../types/verification.type';

@Injectable()
export class VerificationRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Owner just (re)submitted a document — always goes to PENDING, clearing
  // any previous rejection reason/review timestamp so old feedback doesn't
  // linger next to a brand-new submission.
  submit(placeId: string, docPath: string): Promise<Place> {
    return this.prisma.place.update({
      where: { id: placeId },
      data: {
        verificationStatus: PlaceVerificationStatus.PENDING,
        verificationDocPath: docPath,
        verificationSubmittedAt: new Date(),
        verificationReviewedAt: null,
        verificationRejectReason: null,
      },
    });
  }

  review(
    placeId: string,
    status: typeof PlaceVerificationStatus.APPROVED | typeof PlaceVerificationStatus.REJECTED,
    rejectReason: string | null,
  ): Promise<Place> {
    return this.prisma.place.update({
      where: { id: placeId },
      data: {
        verificationStatus: status,
        verificationReviewedAt: new Date(),
        verificationRejectReason: rejectReason,
      },
    });
  }

  async findPending(): Promise<PendingVerificationItem[]> {
    const places = await this.prisma.place.findMany({
      where: {
        verificationStatus: PlaceVerificationStatus.PENDING,
        deletedAt: null,
      },
      select: { id: true, name: true, verificationSubmittedAt: true },
      orderBy: { verificationSubmittedAt: 'asc' },
    });

    return places.map((place) => ({
      placeId: place.id,
      placeName: place.name,
      submittedAt: place.verificationSubmittedAt,
    }));
  }
}
