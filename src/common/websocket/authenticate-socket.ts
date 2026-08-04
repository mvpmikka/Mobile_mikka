import type { JwtService } from '@nestjs/jwt';
import type { ConfigService } from '@nestjs/config';
import type { Socket } from 'socket.io';
import type { UserService } from '../../user/user.service';

interface JwtPayload {
  sub: string;
}

// Shared by every WebSocket gateway in this app (Chat, Notification) —
// factored out once a second gateway needed the exact same handshake auth
// as ChatGateway, rather than duplicating it. Not a base class: multiple
// `@WebSocketGateway()`-decorated classes each need their own
// `handleConnection`, and a plain function composes into that more simply
// than shared inheritance would.
//
// Returns the authenticated user's id, or null if the token is missing,
// invalid, or belongs to a deleted/banned user — the same guarantee
// JwtStrategy.validate gives HTTP requests, reimplemented here because
// there's no Passport strategy hook for a socket.io handshake.
export async function authenticateSocketUser(
  client: Socket,
  jwtService: JwtService,
  configService: ConfigService,
  userService: UserService,
): Promise<string | null> {
  try {
    const token = extractToken(client);
    if (!token) {
      return null;
    }
    const payload = await jwtService.verifyAsync<JwtPayload>(token, {
      secret: configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
    });
    const user = await userService.findById(payload.sub);
    if (!user || user.deletedAt || user.isBanned) {
      return null;
    }
    return user.id;
  } catch {
    return null;
  }
}

// Every connected client joins exactly one room, keyed by their own user
// id — see ChatGateway's comment for why (no per-conversation rooms, no
// client-driven join/leave protocol).
export function userRoom(userId: string): string {
  return `user:${userId}`;
}

function extractToken(client: Socket): string | undefined {
  const authToken = client.handshake.auth?.token as string | undefined;
  if (authToken) {
    return authToken;
  }
  const header = client.handshake.headers.authorization;
  return header?.startsWith('Bearer ') ? header.slice(7) : undefined;
}