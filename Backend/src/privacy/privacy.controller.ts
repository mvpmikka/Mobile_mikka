import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { PrivacyService } from './services/privacy.service';
import { updatePrivacySettingsSchema } from './dto/update-privacy-settings.dto';
import type { UpdatePrivacySettingsDto } from './dto/update-privacy-settings.dto';

@Controller('users/me/privacy-settings')
@UseGuards(JwtAuthGuard)
export class PrivacyController {
  constructor(private readonly privacyService: PrivacyService) {}

  @Get()
  get(@CurrentUser() currentUser: AuthenticatedUser) {
    return this.privacyService.getSettings(currentUser.id);
  }

  @Patch()
  update(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(updatePrivacySettingsSchema))
    dto: UpdatePrivacySettingsDto,
  ) {
    return this.privacyService.updateSettings(currentUser.id, dto);
  }
}