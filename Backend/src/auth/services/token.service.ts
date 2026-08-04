import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomBytes, randomUUID } from 'node:crypto';
import { hashToken } from '../../common/crypto/hash-token';
import { RefreshTokenRepository } from '../repositories/refresh-token.repository';
import { JwtPayload } from '../types/jwt-payload.type';
import { IssuedTokens } from '../types/auth-tokens.type';

@Injectable()
export class TokenService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly refreshTokenRepository: RefreshTokenRepository,
  ) {}

  signAccessToken(userId: string): string {
    const payload: JwtPayload = { sub: userId };
    return this.jwtService.sign(payload);
  }

  async issueTokenPair(userId: string): Promise<IssuedTokens> {
    const familyId = randomUUID();
    const refreshToken = await this.createRefreshToken(userId, familyId);
    return { accessToken: this.signAccessToken(userId), refreshToken };
  }

  // Verifies + rotates a refresh token. Presenting an already-rotated or
  // expired token revokes its whole family — see docs/foundation.md and
  // RefreshTokenRepository.revokeFamily.
  async rotateRefreshToken(rawToken: string): Promise<IssuedTokens> {
    const existing = await this.refreshTokenRepository.findByTokenHash(
      hashToken(rawToken),
    );

    if (!existing) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (existing.revokedAt || existing.expiresAt < new Date()) {
      await this.refreshTokenRepository.revokeFamily(existing.familyId);
      throw new UnauthorizedException('Invalid refresh token');
    }

    await this.refreshTokenRepository.revoke(existing.id);
    const refreshToken = await this.createRefreshToken(
      existing.userId,
      existing.familyId,
    );

    return { accessToken: this.signAccessToken(existing.userId), refreshToken };
  }

  async revokeRefreshToken(rawToken: string): Promise<void> {
    const existing = await this.refreshTokenRepository.findByTokenHash(
      hashToken(rawToken),
    );
    if (existing) {
      await this.refreshTokenRepository.revoke(existing.id);
    }
  }

  async revokeAllForUser(userId: string): Promise<void> {
    await this.refreshTokenRepository.revokeAllForUser(userId);
  }

  private async createRefreshToken(
    userId: string,
    familyId: string,
  ): Promise<string> {
    const rawToken = randomBytes(48).toString('hex');
    const expiresInDays = this.configService.get<number>(
      'REFRESH_TOKEN_EXPIRES_IN_DAYS',
      30,
    );
    const expiresAt = new Date(
      Date.now() + expiresInDays * 24 * 60 * 60 * 1000,
    );

    await this.refreshTokenRepository.create({
      user: { connect: { id: userId } },
      familyId,
      tokenHash: hashToken(rawToken),
      expiresAt,
    });

    return rawToken;
  }
}
