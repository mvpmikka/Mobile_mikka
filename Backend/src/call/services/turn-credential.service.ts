import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import type { IceServer } from '../types/call.type';

const PUBLIC_STUN: IceServer = { urls: 'stun:stun.l.google.com:19302' };

@Injectable()
export class TurnCredentialService {
  constructor(private readonly configService: ConfigService) {}

  // coturn's use-auth-secret (REST API) time-limited credential scheme:
  // username is "<unix-expiry>:<userId>", credential is
  // base64(HMAC-SHA1(sharedSecret, username)) — coturn recomputes this
  // itself to authorize the TURN allocation, no shared DB needed. Falls
  // back to STUN-only while TURN_HOST/TURN_SHARED_SECRET are unset (see
  // .env.example) — calls between devices on the same network or without
  // a restrictive NAT still work, just without relay.
  getIceServers(userId: string): IceServer[] {
    const host = this.configService.get<string>('TURN_HOST') ?? '';
    const secret = this.configService.get<string>('TURN_SHARED_SECRET') ?? '';
    if (!host || !secret) {
      return [PUBLIC_STUN];
    }

    const port = this.configService.get<number>('TURN_PORT') ?? 3478;
    const ttlSeconds =
      this.configService.get<number>('TURN_CREDENTIAL_TTL_SECONDS') ?? 3600;
    const expiry = Math.floor(Date.now() / 1000) + ttlSeconds;
    const username = `${expiry}:${userId}`;
    const credential = createHmac('sha1', secret)
      .update(username)
      .digest('base64');

    return [
      PUBLIC_STUN,
      {
        urls: [
          `turn:${host}:${port}?transport=udp`,
          `turn:${host}:${port}?transport=tcp`,
        ],
        username,
        credential,
      },
    ];
  }
}
