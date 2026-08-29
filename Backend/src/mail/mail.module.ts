import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MAIL_PROVIDER } from './mail.interface';
import { ConsoleMailProvider } from './providers/console.provider';
import { SmtpMailProvider } from './providers/smtp.provider';
import { MailService } from './mail.service';

const logger = new Logger('MailModule');

@Module({
  providers: [
    ConsoleMailProvider,
    SmtpMailProvider,
    {
      provide: MAIL_PROVIDER,
      useFactory: (
        configService: ConfigService,
        consoleProvider: ConsoleMailProvider,
        smtpProvider: SmtpMailProvider,
      ) => {
        // No env var validation exists at startup, so a missing MAIL_HOST
        // in a real environment fails silently otherwise — real emails
        // never send, but nothing errors, because ConsoleMailProvider
        // always resolves successfully. This is the one place that says
        // out loud, at boot, which one is active.
        if (configService.get<string>('MAIL_HOST', '')) {
          logger.log('Using SMTP mail provider (MAIL_HOST is set)');
          return smtpProvider;
        }
        logger.warn(
          'MAIL_HOST is not set — falling back to ConsoleMailProvider. ' +
            'No real emails will be sent; this is expected in local dev only.',
        );
        return consoleProvider;
      },
      inject: [ConfigService, ConsoleMailProvider, SmtpMailProvider],
    },
    MailService,
  ],
  exports: [MailService],
})
export class MailModule {}
