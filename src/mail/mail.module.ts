import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MAIL_PROVIDER } from './mail.interface';
import { ConsoleMailProvider } from './providers/console.provider';
import { SmtpMailProvider } from './providers/smtp.provider';
import { MailService } from './mail.service';

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
      ) =>
        configService.get<string>('MAIL_HOST', '')
          ? smtpProvider
          : consoleProvider,
      inject: [ConfigService, ConsoleMailProvider, SmtpMailProvider],
    },
    MailService,
  ],
  exports: [MailService],
})
export class MailModule {}
