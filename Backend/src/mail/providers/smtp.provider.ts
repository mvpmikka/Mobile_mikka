import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, Transporter } from 'nodemailer';
import { IMailProvider, MailMessage } from '../mail.interface';

// Generic SMTP transport — every provider listed for Mikka (Resend,
// SendGrid, Mailgun, AWS SES) exposes an SMTP endpoint, so switching
// providers is an env-var change, never a code change. A provider-specific
// SDK adapter can implement IMailProvider the same way later if needed.
@Injectable()
export class SmtpMailProvider implements IMailProvider {
  private readonly transporter: Transporter;
  private readonly from: string;

  constructor(configService: ConfigService) {
    this.from = configService.get<string>('MAIL_FROM', '');
    // @nestjs/config returns raw env strings — get<number>/get<boolean> only
    // cast the TypeScript type, they don't parse the value. Without this,
    // MAIL_SECURE="false" is a truthy string and gets treated as secure:true,
    // which breaks the handshake on a STARTTLS port like 587.
    const port = Number(configService.get<string>('MAIL_PORT', '587'));
    const secure = configService.get<string>('MAIL_SECURE', '') === 'true';
    this.transporter = createTransport({
      host: configService.get<string>('MAIL_HOST'),
      port,
      secure,
      auth: {
        user: configService.get<string>('MAIL_USER'),
        pass: configService.get<string>('MAIL_PASSWORD'),
      },
    });
  }

  async send(message: MailMessage): Promise<void> {
    await this.transporter.sendMail({
      from: this.from,
      to: message.to,
      subject: message.subject,
      html: message.html,
      text: message.text,
    });
  }
}
