import { MailMessage } from '../mail.interface';

export function passwordChangedTemplate(): Omit<MailMessage, 'to'> {
  return {
    subject: 'Your Mikka password was changed',
    html: `<p>Your password was just changed. If this was you, no action is needed.</p><p>If you didn't make this change, reset your password immediately.</p>`,
    text: `Your Mikka password was changed. If this wasn't you, reset your password immediately.`,
  };
}
