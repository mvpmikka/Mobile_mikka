import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { VerificationService } from './services/verification.service';
import { reviewVerificationSchema } from './dto/review-verification.dto';
import type { ReviewVerificationDto } from './dto/review-verification.dto';

const MAX_UPLOAD_SIZE_BYTES = 10 * 1024 * 1024;

// Ownership (not just role) is checked inside VerificationService itself,
// not here — see its comment. Every route below still requires ADMIN or
// SUPER_ADMIN at minimum; a plain USER never reaches the service.
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class VerificationController {
  constructor(private readonly verificationService: VerificationService) {}

  @Get('places/:placeId/verification')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  getStatus(
    @Param('placeId') placeId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.verificationService.getStatus(placeId, currentUser);
  }

  @Post('places/:placeId/verification-doc')
  @Roles(Role.ADMIN)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_UPLOAD_SIZE_BYTES },
      fileFilter: (_req, file, callback) => {
        callback(null, file.mimetype.startsWith('image/'));
      },
    }),
  )
  submit(
    @Param('placeId') placeId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('file is required and must be an image');
    }
    return this.verificationService.submit(
      placeId,
      currentUser.id,
      file.buffer,
    );
  }

  @Patch('places/:placeId/verification/review')
  @Roles(Role.SUPER_ADMIN)
  review(
    @Param('placeId') placeId: string,
    @Body(new ZodValidationPipe(reviewVerificationSchema))
    dto: ReviewVerificationDto,
  ) {
    return this.verificationService.review(
      placeId,
      dto.status,
      dto.rejectReason,
    );
  }

  @Get('verification/pending')
  @Roles(Role.SUPER_ADMIN)
  listPending() {
    return this.verificationService.listPending();
  }
}
