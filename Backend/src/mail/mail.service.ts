import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MAIL_PROVIDER } from './mail.interface';
import type { IMailProvider, MailMessage } from './mail.interface';
import { verificationTemplate } from './templates/verification.template';
import { forgotPasswordTemplate } from './templates/forgot-password.template';
import { passwordChangedTemplate } from './templates/password-changed.template';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(
    @Inject(MAIL_PROVIDER) private readonly provider: IMailProvider,
    private readonly configService: ConfigService,
  ) {}

  // Gmail (and most mail clients) strip/refuse to linkify non-http(s)
  // href schemes like "mikka://" for security reasons, so emails link to
  // an https bridge page (AuthController's GET /auth/verify-email etc.)
  // which then redirects into the app via the mikka:// deep link.
  async sendVerificationEmail(to: string, token: string): Promise<void> {
    const link = `${this.frontendUrl}/auth/verify-email?token=${token}`;
    await this.safeSend({ to, ...verificationTemplate({ link }) });
  }

  async sendForgotPasswordEmail(to: string, token: string): Promise<void> {
    const link = `${this.frontendUrl}/auth/reset-password?token=${token}`;
    await this.safeSend({ to, ...forgotPasswordTemplate({ link }) });
  }

  private get frontendUrl(): string {
    return this.configService.get<string>('FRONTEND_URL', '');
  }

  async sendPasswordChangedEmail(to: string): Promise<void> {
    await this.safeSend({ to, ...passwordChangedTemplate() });
  }

  // Mail delivery failures must never break the calling business
  // transaction (registration, password reset, ...) — log and move on.
  private async safeSend(message: MailMessage): Promise<void> {
    try {
      await this.provider.send(message);
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to send email to ${message.to}: ${reason}`);
    }
  }
}
