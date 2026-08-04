import { Injectable, Logger } from '@nestjs/common';
import { IMailProvider, MailMessage } from '../mail.interface';

// Selected by MailModule whenever MAIL_HOST is unset. Lets every flow that
// sends email (verification, password reset...) be fully exercisable in
// dev without real SMTP credentials — read the link out of the log.
@Injectable()
export class ConsoleMailProvider implements IMailProvider {
  private readonly logger = new Logger('MailProvider:console');

  send(message: MailMessage): Promise<void> {
    this.logger.log(
      `to=${message.to} subject="${message.subject}"\n${message.text ?? message.html}`,
    );
    return Promise.resolve();
  }
}
