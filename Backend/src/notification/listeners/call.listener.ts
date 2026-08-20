import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationService } from '../services/notification.service';
import { NotificationRepository } from '../repositories/notification.repository';
import {
  CALL_MISSED_EVENT,
  type CallMissedEvent,
} from '../../call/events/call-missed.event';

@Injectable()
export class CallListener {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly notificationRepository: NotificationRepository,
  ) {}

  @OnEvent(CALL_MISSED_EVENT)
  async handle(event: CallMissedEvent): Promise<void> {
    const caller = await this.notificationRepository.findUserProfile(
      event.callerId,
    );
    const name = caller?.username ?? 'Someone';
    const kind = event.type === 'VIDEO' ? 'video call' : 'call';
    await this.notificationService.notify(
      event.calleeId,
      'MISSED_CALL',
      `Missed ${kind} from ${name}`,
      { callId: event.callId, callerId: event.callerId, type: event.type },
    );
  }
}
