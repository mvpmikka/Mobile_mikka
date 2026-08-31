import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IMailProvider, MailMessage } from '../mail.interface';

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// Brevo's transactional API is plain HTTPS (port 443), unlike SMTP
// (port 587/465/25) which Render's containers can't reach outbound at
// all — connections just hang until Render's own edge proxy times out
// with a 502, regardless of which IP family they resolve to.
@Injectable()
export class BrevoMailProvider implements IMailProvider {
  private readonly apiKey: string;
  private readonly senderName: string;
  private readonly senderEmail: string;

  constructor(configService: ConfigService) {
    this.apiKey = configService.get<string>('BREVO_API_KEY', '');
    const from = configService.get<string>('MAIL_FROM', '');
    const match = from.match(/^(.*)<(.+)>$/);
    if (match) {
      this.senderName = match[1].trim() || 'Mikka';
      this.senderEmail = match[2].trim();
    } else {
      this.senderName = 'Mikka';
      this.senderEmail = from;
    }
  }

  async send(message: MailMessage): Promise<void> {
    const response = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'api-key': this.apiKey,
      },
      body: JSON.stringify({
        sender: { name: this.senderName, email: this.senderEmail },
        to: [{ email: message.to }],
        subject: message.subject,
        htmlContent: message.html,
        textContent: message.text,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Brevo API ${response.status}: ${body}`);
    }
  }
}
