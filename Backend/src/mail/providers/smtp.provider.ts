import { dns } from 'node:dns';
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, Transporter } from 'nodemailer';
import { IMailProvider, MailMessage } from '../mail.interface';

// Generic SMTP transport — every provider listed for Mikka (Resend,
// SendGrid, Mailgun, AWS SES) exposes an SMTP endpoint, so switching
// providers is an env-var change, never a code change. A provider-specific
// SDK adapter can implement IMailProvider the same way later if needed.
@Injectable()
export class SmtpMailProvider implements IMailProvider, OnModuleInit {
  private readonly logger = new Logger(SmtpMailProvider.name);
  private readonly from: string;
  private readonly host: string;
  private readonly port: number;
  private readonly secure: boolean;
  private readonly user: string;
  private readonly pass: string;
  private transporter: Transporter;

  constructor(private readonly configService: ConfigService) {
    this.from = configService.get<string>('MAIL_FROM', '');
    this.host = configService.get<string>('MAIL_HOST', '');
    // @nestjs/config returns raw env strings — get<number>/get<boolean> only
    // cast the TypeScript type, they don't parse the value. Without this,
    // MAIL_SECURE="false" is a truthy string and gets treated as secure:true,
    // which breaks the handshake on a STARTTLS port like 587.
    this.port = Number(configService.get<string>('MAIL_PORT', '587'));
    this.secure = configService.get<string>('MAIL_SECURE', '') === 'true';
    this.user = configService.get<string>('MAIL_USER', '');
    this.pass = configService.get<string>('MAIL_PASSWORD', '');
    // Built here as a same-family fallback so `send()` never has an
    // undefined transporter — replaced with an IP-pinned one below once
    // onModuleInit's DNS lookup resolves.
    this.transporter = this.buildTransporter(this.host);
  }

  async onModuleInit(): Promise<void> {
    // nodemailer resolves both A (IPv4) and AAAA (IPv6) records for the
    // host and picks one at RANDOM to connect to — it does not fall back
    // to IPv4 on failure in a timely way. Render's containers report an
    // IPv6 interface that isn't actually routable, so an unlucky AAAA pick
    // either fails fast (ENETUNREACH) or, worse, hangs until nodemailer's
    // own ~2 minute connection timeout. Resolving the A record ourselves
    // and connecting to that literal IP sidesteps the random pick entirely.
    try {
      const { address } = await dns.promises.lookup(this.host, { family: 4 });
      this.transporter = this.buildTransporter(address, this.host);
      this.logger.log(`Resolved ${this.host} -> ${address} (IPv4) for SMTP`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      this.logger.warn(
        `Could not resolve an IPv4 address for ${this.host} (${reason}) — ` +
          'falling back to hostname-based resolution, which may hit the ' +
          'IPv6 issue this lookup exists to avoid.',
      );
    }
  }

  private buildTransporter(host: string, servername?: string): Transporter {
    return createTransport({
      host,
      port: this.port,
      secure: this.secure,
      // Only meaningful when `host` is a literal IP (the post-onModuleInit
      // case) — TLS/STARTTLS needs the real hostname for SNI and for
      // matching it against Gmail's certificate, since the IP itself won't.
      ...(servername ? { servername } : {}),
      auth: {
        user: this.user,
        pass: this.pass,
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
