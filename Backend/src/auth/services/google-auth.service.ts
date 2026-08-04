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
}

@Injectable()
export class GoogleAuthService {
  private readonly client: OAuth2Client;
  private readonly clientId: string;

  constructor(configService: ConfigService) {
    this.clientId = configService.get<string>('GOOGLE_CLIENT_ID', '');
    this.client = new OAuth2Client(this.clientId);
  }

  // Verifies the token's signature against Google's public keys and reads
  // claims from the verified payload only — never trust client-supplied
  // profile JSON directly (see docs/foundation.md security notes).
  async verifyIdToken(idToken: string): Promise<GoogleProfile> {
    if (!this.clientId) {
      throw new BadRequestException('Google sign-in is not configured yet');
    }

    const ticket = await this.client
      .verifyIdToken({ idToken, audience: this.clientId })
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
    };
  }
}
