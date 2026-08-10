import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';

export interface GoogleProfile {
  providerUserId: string;
  email: string;
  emailVerified: boolean;
  fullName?: string;
  avatarUrl?: string;
}

@Injectable()
export class GoogleAuthService {
  private readonly client: OAuth2Client;
  private readonly clientId: string;
  private readonly audiences: string[];

  constructor(configService: ConfigService) {
    this.clientId = configService.get<string>('GOOGLE_CLIENT_ID', '');
    const iosClientId = configService.get<string>('GOOGLE_IOS_CLIENT_ID', '');
    this.audiences = [this.clientId, iosClientId].filter(Boolean);
    this.client = new OAuth2Client(this.clientId);
  }

  // Verifies the token's signature against Google's public keys and reads
  // claims from the verified payload only — never trust client-supplied
  // profile JSON directly (see docs/foundation.md security notes).
  async verifyIdToken(idToken: string): Promise<GoogleProfile> {
    if (!this.audiences.length) {
      throw new BadRequestException('Google sign-in is not configured yet');
    }

    const ticket = await this.client
      .verifyIdToken({ idToken, audience: this.audiences })
      .catch(() => {
        throw new UnauthorizedException('Invalid Google ID token');
      });

    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email) {
      throw new UnauthorizedException('Invalid Google ID token');
    }

    return {
      providerUserId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified ?? false,
      fullName: payload.name,
      avatarUrl: payload.picture,
    };
  }
}
