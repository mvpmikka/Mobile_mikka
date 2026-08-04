import { MailMessage } from '../mail.interface';

export function verificationTemplate(props: {
  link: string;
}): Omit<MailMessage, 'to'> {
  return {
    subject: 'Verify your Mikka account',
    html: `<p>Welcome to Mikka! Confirm your email address to finish setting up your account:</p><p><a href="${props.link}">${props.link}</a></p><p>If you didn't create this account, you can ignore this email.</p>`,
    text: `Welcome to Mikka! Verify your email: ${props.link}`,
  };
}
