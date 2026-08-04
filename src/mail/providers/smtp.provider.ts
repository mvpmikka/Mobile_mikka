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
    this.transporter = createTransport({
      host: configService.get<string>('MAIL_HOST'),
      port: configService.get<number>('MAIL_PORT'),
      secure: configService.get<boolean>('MAIL_SECURE'),
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
