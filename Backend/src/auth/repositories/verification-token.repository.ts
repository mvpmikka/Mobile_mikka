import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  Prisma,
  VerificationToken,
  VerificationTokenPurpose,
} from '../../../generated/prisma/client';

@Injectable()
export class VerificationTokenRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(
    data: Prisma.VerificationTokenCreateInput,
  ): Promise<VerificationToken> {
    return this.prisma.verificationToken.create({ data });
  }

  findByTokenHash(tokenHash: string): Promise<VerificationToken | null> {
    return this.prisma.verificationToken.findUnique({ where: { tokenHash } });
  }

  consume(id: string): Promise<VerificationToken> {
    return this.prisma.verificationToken.update({
      where: { id },
      data: { consumedAt: new Date() },
    });
  }

  // Requesting a new token of the same purpose (e.g. another reset link)
  // supersedes any outstanding one, so an older leaked link stops working.
  invalidateOutstanding(
    userId: string,
    purpose: VerificationTokenPurpose,
  ): Promise<Prisma.BatchPayload> {
    return this.prisma.verificationToken.updateMany({
      where: { userId, purpose, consumedAt: null },
      data: { consumedAt: new Date() },
    });
  }
}
