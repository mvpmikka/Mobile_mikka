import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { registerSchema } from './dto/register.dto';
import type { RegisterDto } from './dto/register.dto';
import { loginSchema } from './dto/login.dto';
import type { LoginDto } from './dto/login.dto';
import { googleLoginSchema } from './dto/google-login.dto';
import type { GoogleLoginDto } from './dto/google-login.dto';
import { refreshTokenSchema } from './dto/refresh-token.dto';
import type { RefreshTokenDto } from './dto/refresh-token.dto';
import { verifyEmailSchema } from './dto/verify-email.dto';
import type { VerifyEmailDto } from './dto/verify-email.dto';
import { resendVerificationSchema } from './dto/resend-verification.dto';
import type { ResendVerificationDto } from './dto/resend-verification.dto';
import { forgotPasswordSchema } from './dto/forgot-password.dto';
import type { ForgotPasswordDto } from './dto/forgot-password.dto';
import { resetPasswordSchema } from './dto/reset-password.dto';
import type { ResetPasswordDto } from './dto/reset-password.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  register(@Body(new ZodValidationPipe(registerSchema)) dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  login(@Body(new ZodValidationPipe(loginSchema)) dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  loginWithGoogle(
    @Body(new ZodValidationPipe(googleLoginSchema)) dto: GoogleLoginDto,
  ) {
    return this.authService.loginWithGoogle(dto.idToken);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(
    @Body(new ZodValidationPipe(refreshTokenSchema)) dto: RefreshTokenDto,
  ) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  logout(
    @Body(new ZodValidationPipe(refreshTokenSchema)) dto: RefreshTokenDto,
  ) {
    return this.authService.logout(dto.refreshToken);
  }

  @Post('verify-email')
  @HttpCode(HttpStatus.NO_CONTENT)
  verifyEmail(
    @Body(new ZodValidationPipe(verifyEmailSchema)) dto: VerifyEmailDto,
  ) {
    return this.authService.verifyEmail(dto.token);
  }

  @Post('resend-verification')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  resendVerification(
    @Body(new ZodValidationPipe(resendVerificationSchema))
    dto: ResendVerificationDto,
  ) {
    return this.authService.resendVerification(dto.email);
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  forgotPassword(
    @Body(new ZodValidationPipe(forgotPasswordSchema)) dto: ForgotPasswordDto,
  ) {
    return this.authService.forgotPassword(dto.email);
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  resetPassword(
    @Body(new ZodValidationPipe(resetPasswordSchema)) dto: ResetPasswordDto,
  ) {
    return this.authService.resetPassword(dto.token, dto.newPassword);
  }
}
