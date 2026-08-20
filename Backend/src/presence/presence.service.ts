import { Injectable } from '@nestjs/common';

// Ref-counted rather than a plain Set: the same user can hold multiple
// open sockets (e.g. two devices, or a reconnect race), and "online"
// must only flip to false once every connection has closed. Single
// process/instance only — no Redis adapter, matching this app's current
// scale (see plan). Its own module (not folded into ChatGateway) so
// FriendshipModule can read presence without importing ChatModule,
// which would otherwise create a module import cycle (ChatModule
// already imports FriendshipModule for the friends-only conversation
// check).
@Injectable()
export class PresenceService {
  private readonly connectionCounts = new Map<string, number>();

  markOnline(userId: string): void {
    const current = this.connectionCounts.get(userId) ?? 0;
    this.connectionCounts.set(userId, current + 1);
  }

  markOffline(userId: string): void {
    const current = this.connectionCounts.get(userId) ?? 0;
    if (current <= 1) {
      this.connectionCounts.delete(userId);
      return;
    }
    this.connectionCounts.set(userId, current - 1);
  }

  isOnline(userId: string): boolean {
    return this.connectionCounts.has(userId);
  }
}
