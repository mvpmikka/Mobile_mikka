import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { CallRepository } from '../repositories/call.repository';
import { FriendshipRepository } from '../../friendship/repositories/friendship.repository';
import { CallBusyError } from '../errors/call-busy.error';
import { CALL_MISSED_EVENT } from '../events/call-missed.event';
import type { CallSession, CallType } from '../../../generated/prisma/client';

const ENDED_STATUSES = ['DECLINED', 'MISSED', 'ENDED', 'FAILED'];

@Injectable()
export class CallService {
  constructor(
    private readonly callRepository: CallRepository,
    private readonly friendshipRepository: FriendshipRepository,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // Requires an existing friendship (same gate ConversationService.create
  // uses) and rejects if either party is already RINGING/ACCEPTED
  // elsewhere — a CallSession row IS the live "in a call" state, not just
  // a log, so this check reads the same table it writes to.
  async initiate(
    callerId: string,
    calleeId: string,
    type: CallType,
    conversationId?: string,
  ): Promise<CallSession> {
    if (callerId === calleeId) {
      throw new BadRequestException("You can't call yourself");
    }
    const areFriends = await this.friendshipRepository.exists(
      callerId,
      calleeId,
    );
    if (!areFriends) {
      throw new ForbiddenException('You can only call friends');
    }
    const callerBusy = await this.callRepository.findActiveForUser(callerId);
    if (callerBusy) {
      throw new BadRequestException('You are already in a call');
    }
    const calleeBusy = await this.callRepository.findActiveForUser(calleeId);
    if (calleeBusy) {
      throw new CallBusyError();
    }
    return this.callRepository.create(callerId, calleeId, type, conversationId);
  }

  getById(id: string): Promise<CallSession | null> {
    return this.callRepository.findById(id);
  }

  async accept(id: string, userId: string): Promise<CallSession> {
    const call = await this.requireParticipant(id, userId);
    if (call.calleeId !== userId) {
      throw new ForbiddenException('Only the callee can accept a call');
    }
    if (call.status !== 'RINGING') {
      throw new BadRequestException('Call is no longer ringing');
    }
    return this.callRepository.updateStatus(id, 'ACCEPTED', {
      acceptedAt: new Date(),
    });
  }

  async reject(id: string, userId: string): Promise<CallSession> {
    const call = await this.requireParticipant(id, userId);
    if (call.status !== 'RINGING') {
      throw new BadRequestException('Call is no longer ringing');
    }
    return this.callRepository.updateStatus(id, 'DECLINED', {
      endedAt: new Date(),
      endReason: 'declined',
    });
  }

  async hangup(id: string, userId: string): Promise<CallSession> {
    const call = await this.requireParticipant(id, userId);
    if (ENDED_STATUSES.includes(call.status)) {
      return call;
    }
    return this.callRepository.updateStatus(id, 'ENDED', {
      endedAt: new Date(),
      endReason: 'hangup',
    });
  }

  // Called by CallGateway's 45s ringing timer, never by a user action —
  // returns null if the call was already accepted/declined in the
  // meantime (timer firing races against the callee answering).
  async markMissed(id: string): Promise<CallSession | null> {
    const call = await this.callRepository.findById(id);
    if (!call || call.status !== 'RINGING') {
      return null;
    }
    const updated = await this.callRepository.updateStatus(id, 'MISSED', {
      endedAt: new Date(),
      endReason: 'no_answer',
    });
    this.eventEmitter.emit(CALL_MISSED_EVENT, {
      callId: updated.id,
      callerId: updated.callerId,
      calleeId: updated.calleeId,
      type: updated.type,
    });
    return updated;
  }

  private async requireParticipant(
    id: string,
    userId: string,
  ): Promise<CallSession> {
    const call = await this.callRepository.findById(id);
    if (!call) {
      throw new NotFoundException('Call not found');
    }
    if (call.callerId !== userId && call.calleeId !== userId) {
      throw new ForbiddenException('You are not part of this call');
    }
    return call;
  }
}
