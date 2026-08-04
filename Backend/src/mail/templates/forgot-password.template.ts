import { MailMessage } from '../mail.interface';

export function forgotPasswordTemplate(props: {
  link: string;
}): Omit<MailMessage, 'to'> {
  return {
    subject: 'Reset your Mikka password',
    html: `<p>We received a request to reset your password. Choose a new one here:</p><p><a href="${props.link}">${props.link}</a></p><p>If you didn't request this, you can safely ignore this email — your password won't change.</p>`,
    text: `Reset your Mikka password: ${props.link}`,
  };
}
