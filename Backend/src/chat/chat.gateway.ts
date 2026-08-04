import { Logger } from '@nestjs/common';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UserService } from '../user/user.service';
import { authenticateSocketUser, userRoom } from '../common/websocket/authenticate-socket';
import type { MessageItem } from './types/chat.type';

interface ReactionUpdatePayload {
  conversationId: string;
  messageId: string;
  reactions: { emoji: string; count: number }[];
}

// No CORS config here, matching the rest of this app (main.ts never calls
// app.enableCors() either) — the client is a native mobile app, not a
// browser, so CORS doesn't apply. Revisit only if a browser-based client
// (e.g. an admin panel) needs to connect directly.
//
// Push-only: REST (ChatController) is the source of truth for every
// mutation (send/delete a message, react). This gateway's only job is
// telling already-connected clients "something changed" so they can
// re-fetch or apply the pushed payload — it never accepts writes itself.
@WebSocketGateway({ namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ChatGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly userService: UserService,
  ) {}

  // Every connected client joins exactly one room, keyed by their own user
  // id — not one room per conversation. Simpler than a client-driven
  // join_conversation/leave_conversation protocol: broadcasting a
  // conversation event just means emitting to each active participant's
  // user-room, computed server-side from ConversationParticipant, so the
  // client never has to manage room membership itself.
  async handleConnection(client: Socket): Promise<void> {
    const userId = await authenticateSocketUser(
      client,
      this.jwtService,
      this.configService,
      this.userService,
    );
    if (!userId) {
      this.logger.warn('WebSocket auth failed, disconnecting client');
      client.disconnect(true);
      return;
    }
    client.data.userId = userId;
    await client.join(userRoom(userId));
  }

  handleDisconnect(): void {
    // socket.io removes room membership automatically on disconnect —
    // nothing else to clean up.
  }

  broadcastNewMessage(recipientUserIds: string[], message: MessageItem): void {
    this.emitToUsers(recipientUserIds, 'new_message', message);
  }

  broadcastMessageDeleted(
    recipientUserIds: string[],
    conversationId: string,
    messageId: string,
  ): void {
    this.emitToUsers(recipientUserIds, 'message_deleted', {
      conversationId,
      messageId,
    });
  }

  // Deliberately excludes the per-viewer `reactedByMe` field that
  // MessageItem.reactions carries — that field is personalized per
  // recipient, but one broadcast payload is shared by everyone. Clients
  // derive their own reactedByMe locally (they know if they're the one
  // who just reacted).
  broadcastReactionUpdated(
    recipientUserIds: string[],
    payload: ReactionUpdatePayload,
  ): void {
    this.emitToUsers(recipientUserIds, 'reaction_updated', payload);
  }

  private emitToUsers(userIds: string[], event: string, payload: unknown): void {
    for (const userId of userIds) {
      this.server.to(userRoom(userId)).emit(event, payload);
    }
  }
}