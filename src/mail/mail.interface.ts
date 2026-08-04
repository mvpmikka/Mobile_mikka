export interface MailMessage {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export interface IMailProvider {
  send(message: MailMessage): Promise<void>;
}

export const MAIL_PROVIDER = Symbol('MAIL_PROVIDER');
