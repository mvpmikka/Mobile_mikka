import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  CallSession,
  CallStatus,
  CallType,
} from '../../../generated/prisma/client';

@Injectable()
export class CallRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(
    callerId: string,
    calleeId: string,
    type: CallType,
    conversationId?: string,
  ): Promise<CallSession> {
    return this.prisma.callSession.create({
      data: { callerId, calleeId, type, conversationId },
    });
  }

  findById(id: string): Promise<CallSession | null> {
    return this.prisma.callSession.findUnique({ where: { id } });
  }

  // Whether this user is caller or callee on any call still RINGING/
  // ACCEPTED — used to reject a second concurrent call attempt (glare)
  // with call:busy, rather than letting two calls race for the same user.
  findActiveForUser(userId: string): Promise<CallSession | null> {
    return this.prisma.callSession.findFirst({
      where: {
        status: { in: ['RINGING', 'ACCEPTED'] },
        OR: [{ callerId: userId }, { calleeId: userId }],
      },
    });
  }

  updateStatus(
    id: string,
    status: CallStatus,
    extra?: { acceptedAt?: Date; endedAt?: Date; endReason?: string },
  ): Promise<CallSession> {
    return this.prisma.callSession.update({
      where: { id },
      data: { status, ...extra },
    });
  }
}
