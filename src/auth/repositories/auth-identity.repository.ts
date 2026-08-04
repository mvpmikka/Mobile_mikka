import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  AuthIdentity,
  AuthProvider,
  Prisma,
} from '../../../generated/prisma/client';

@Injectable()
export class AuthIdentityRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByProvider(
    provider: AuthProvider,
    providerUserId: string,
  ): Promise<AuthIdentity | null> {
    return this.prisma.authIdentity.findUnique({
      where: { provider_providerUserId: { provider, providerUserId } },
    });
  }

  findByUserAndProvider(
    userId: string,
    provider: AuthProvider,
  ): Promise<AuthIdentity | null> {
    return this.prisma.authIdentity.findUnique({
      where: { userId_provider: { userId, provider } },
    });
  }

  create(data: Prisma.AuthIdentityCreateInput): Promise<AuthIdentity> {
    return this.prisma.authIdentity.create({ data });
  }

  updatePasswordHash(id: string, passwordHash: string): Promise<AuthIdentity> {
    return this.prisma.authIdentity.update({
      where: { id },
      data: { passwordHash },
    });
  }
}
