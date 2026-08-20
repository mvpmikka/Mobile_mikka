import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { TurnCredentialService } from './services/turn-credential.service';

@Controller('call')
@UseGuards(JwtAuthGuard)
export class CallController {
  constructor(private readonly turnCredentialService: TurnCredentialService) {}

  @Get('ice-servers')
  getIceServers(@CurrentUser() currentUser: AuthenticatedUser) {
    return {
      iceServers: this.turnCredentialService.getIceServers(currentUser.id),
    };
  }
}
