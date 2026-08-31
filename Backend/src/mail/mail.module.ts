import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MAIL_PROVIDER } from './mail.interface';
import { ConsoleMailProvider } from './providers/console.provider';
import { SmtpMailProvider } from './providers/smtp.provider';
import { BrevoMailProvider } from './providers/brevo.provider';
import { MailService } from './mail.service';

const logger = new Logger('MailModule');

@Module({
  providers: [
    ConsoleMailProvider,
    SmtpMailProvider,
    BrevoMailProvider,
    {
      provide: MAIL_PROVIDER,
      useFactory: (
        configService: ConfigService,
        consoleProvider: ConsoleMailProvider,
        smtpProvider: SmtpMailProvider,
        brevoProvider: BrevoMailProvider,
      ) => {
        // No env var validation exists at startup, so a missing MAIL_HOST
        // in a real environment fails silently otherwise — real emails
        // never send, but nothing errors, because ConsoleMailProvider
        // always resolves successfully. This is the one place that says
        // out loud, at boot, which one is active.
        //
        // Brevo (HTTPS API, port 443) takes priority over raw SMTP because
        // Render blocks outbound SMTP ports (25/465/587) entirely — SMTP
        // connections there just hang until Render's edge proxy 502s.
        if (configService.get<string>('BREVO_API_KEY', '')) {
          logger.log('Using Brevo mail provider (BREVO_API_KEY is set)');
          return brevoProvider;
        }
        if (configService.get<string>('MAIL_HOST', '')) {
          logger.log('Using SMTP mail provider (MAIL_HOST is set)');
          return smtpProvider;
        }
        logger.warn(
          'Neither BREVO_API_KEY nor MAIL_HOST is set — falling back to ' +
            'ConsoleMailProvider. No real emails will be sent; this is ' +
            'expected in local dev only.',
        );
        return consoleProvider;
      },
      inject: [ConfigService, ConsoleMailProvider, SmtpMailProvider, BrevoMailProvider],
    },
    MailService,
  ],
  exports: [MailService],
})
export class MailModule {}
