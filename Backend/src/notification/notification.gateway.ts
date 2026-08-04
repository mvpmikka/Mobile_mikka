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
import type { NotificationItem } from './types/notification.type';

// Same per-user-room, push-only, JWT-handshake-auth design as ChatGateway
// (see its comments for the full reasoning) — this gateway exists
// separately rather than folding into ChatGateway because Notification
// and Chat are independent modules; sharing one gateway class would mean
// one importing the other for no reason beyond "they're both sockets."
// The actual auth logic is shared via authenticateSocketUser, so this
// isn't a duplicate of that reasoning, just the same conclusion applied
// to a second, unrelated namespace.
@WebSocketGateway({ namespace: '/notifications' })
export class NotificationGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(NotificationGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly userService: UserService,
  ) {}

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

  push(recipientUserId: string, notification: NotificationItem): void {
    this.server.to(userRoom(recipientUserId)).emit('notification', notification);
  }
}