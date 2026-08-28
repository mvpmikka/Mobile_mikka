import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import type { AuthenticatedUser } from './strategies/jwt.strategy';
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

  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  deleteAccount(@CurrentUser() currentUser: AuthenticatedUser) {
    return this.authService.deleteAccount(currentUser.id);
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

  // Gmail (and most mail clients) strip or refuse to linkify non-http(s)
  // href schemes like "mikka://" inside emails, so the verification/reset
  // emails link here instead — this page's button navigates into the app
  // via the mikka:// deep link. No auto-redirect (meta refresh): browsers
  // only show the "Open in Mikka?" permission prompt for a real user
  // click, and an automatic attempt on page load can suppress it entirely.
  @Get('verify-email')
  @Header('Content-Type', 'text/html')
  verifyEmailPage(@Query('token') token?: string) {
    return this.buildDeepLinkPage('verify-email', token);
  }

  @Get('reset-password')
  @Header('Content-Type', 'text/html')
  resetPasswordPage(@Query('token') token?: string) {
    return this.buildDeepLinkPage('reset-password', token);
  }

  private buildDeepLinkPage(host: string, token?: string): string {
    // encodeURIComponent also neutralizes any HTML-special characters
    // (<, >, ", ', &) the token might contain, so the result is safe to
    // embed directly into the href/meta-refresh attributes below.
    const deepLink = token
      ? `mikka://${host}?token=${encodeURIComponent(token)}`
      : `mikka://${host}`;

    return `<!doctype html>
<html lang="uz">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Mikka</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #FBEEE0; color: #2b2b2b; text-align: center; padding: 72px 24px; }
  a.btn { display: inline-block; margin-top: 24px; padding: 14px 32px; background: #E97A3C; color: #fff; border-radius: 28px; text-decoration: none; font-weight: 600; }
</style>
</head>
<body>
  <h2>Emailingiz tasdiqlanmoqda</h2>
  <p>Davom etish uchun quyidagi tugmani bosing:</p>
  <a class="btn" href="${deepLink}">Ilovada ochish</a>
</body>
</html>`;
  }
}
