import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { PlaceRatingSummary } from '../../../generated/prisma/client';

// Read-only from the application's perspective — the row itself is
// maintained entirely by a DB trigger on `reviews` (see the migration).
@Injectable()
export class PlaceRatingSummaryRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByPlaceId(placeId: string): Promise<PlaceRatingSummary | null> {
    return this.prisma.placeRatingSummary.findUnique({ where: { placeId } });
  }
}
