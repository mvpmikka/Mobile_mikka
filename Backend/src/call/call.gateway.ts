import { Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UserService } from '../user/user.service';
import {
  authenticateSocketUser,
  userRoom,
} from '../common/websocket/authenticate-socket';
import { CallService } from './services/call.service';
import { CallBusyError } from './errors/call-busy.error';
import type { CallType } from '../../generated/prisma/client';

const RINGING_TIMEOUT_MS = 45_000;

interface InvitePayload {
  calleeId: string;
  type: CallType;
  conversationId?: string;
}

interface CallIdPayload {
  callId: string;
}

interface SignalPayload {
  callId: string;
  sdp?: unknown;
  candidate?: unknown;
}

// Bidirectional, unlike ChatGateway/NotificationGateway: offer/answer/ICE
// have no REST equivalent, so this gateway IS the signalling transport,
// not just a push channel for REST-driven mutations. REST
// (CallController) only exposes GET /call/ice-servers — everything about
// a call's lifecycle happens over this socket.
@WebSocketGateway({ namespace: '/call' })
export class CallGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(CallGateway.name);
  private readonly ringingTimers = new Map<string, NodeJS.Timeout>();

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly userService: UserService,
    private readonly callService: CallService,
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
    // socket.io removes room membership automatically on disconnect — an
    // in-progress call just keeps ringing/running until the other party
    // hangs up or the 45s ringing timer fires.
  }

  @SubscribeMessage('call:invite')
  async handleInvite(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: InvitePayload,
  ): Promise<{ callId: string } | { error: string; message: string }> {
    const callerId = client.data.userId as string;
    try {
      const call = await this.callService.initiate(
        callerId,
        payload.calleeId,
        payload.type,
        payload.conversationId,
      );
      this.server.to(userRoom(payload.calleeId)).emit('call:incoming', {
        callId: call.id,
        callerId,
        type: call.type,
        conversationId: call.conversationId,
      });
      this.startRingingTimer(call.id, payload.calleeId);
      return { callId: call.id };
    } catch (error) {
      if (error instanceof CallBusyError) {
        return { error: 'busy', message: 'User is already in a call' };
      }
      const message = error instanceof Error ? error.message : 'Call failed';
      return { error: 'failed', message };
    }
  }

  @SubscribeMessage('call:accept')
  async handleAccept(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: CallIdPayload,
  ): Promise<void> {
    const userId = client.data.userId as string;
    this.clearRingingTimer(payload.callId);
    const call = await this.callService.accept(payload.callId, userId);
    this.server
      .to(userRoom(call.callerId))
      .emit('call:accepted', { callId: call.id });
  }

  @SubscribeMessage('call:reject')
  async handleReject(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: CallIdPayload,
  ): Promise<void> {
    const userId = client.data.userId as string;
    this.clearRingingTimer(payload.callId);
    const call = await this.callService.reject(payload.callId, userId);
    this.server
      .to(userRoom(call.callerId))
      .emit('call:rejected', { callId: call.id });
  }

  @SubscribeMessage('call:hangup')
  async handleHangup(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: CallIdPayload,
  ): Promise<void> {
    const userId = client.data.userId as string;
    this.clearRingingTimer(payload.callId);
    const call = await this.callService.hangup(payload.callId, userId);
    const otherUserId =
      call.callerId === userId ? call.calleeId : call.callerId;
    this.server
      .to(userRoom(otherUserId))
      .emit('call:ended', { callId: call.id });
  }

  @SubscribeMessage('call:offer')
  async handleOffer(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SignalPayload,
  ): Promise<void> {
    await this.relay(client, payload, 'call:offer');
  }

  @SubscribeMessage('call:answer')
  async handleAnswer(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SignalPayload,
  ): Promise<void> {
    await this.relay(client, payload, 'call:answer');
  }

  @SubscribeMessage('call:ice-candidate')
  async handleIceCandidate(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SignalPayload,
  ): Promise<void> {
    await this.relay(client, payload, 'call:ice-candidate');
  }

  // offer/answer/ICE candidates are forwarded verbatim to whichever side
  // of the call didn't send them — this gateway never inspects SDP/ICE
  // content, it's a dumb relay between the two peers.
  private async relay(
    client: Socket,
    payload: SignalPayload,
    event: string,
  ): Promise<void> {
    const userId = client.data.userId as string;
    const call = await this.callService.getById(payload.callId);
    if (!call) return;
    const otherUserId =
      call.callerId === userId ? call.calleeId : call.callerId;
    this.server.to(userRoom(otherUserId)).emit(event, payload);
  }

  private startRingingTimer(callId: string, calleeId: string): void {
    const timer = setTimeout(() => {
      void this.handleRingingTimeout(callId, calleeId);
    }, RINGING_TIMEOUT_MS);
    this.ringingTimers.set(callId, timer);
  }

  private clearRingingTimer(callId: string): void {
    const timer = this.ringingTimers.get(callId);
    if (timer) {
      clearTimeout(timer);
      this.ringingTimers.delete(callId);
    }
  }

  private async handleRingingTimeout(
    callId: string,
    calleeId: string,
  ): Promise<void> {
    this.ringingTimers.delete(callId);
    const call = await this.callService.markMissed(callId);
    if (!call) return;
    this.server.to(userRoom(call.callerId)).emit('call:missed', { callId });
    this.server.to(userRoom(calleeId)).emit('call:missed', { callId });
  }
}
