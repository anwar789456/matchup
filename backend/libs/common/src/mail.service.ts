import { Global, Injectable, Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, Transporter } from 'nodemailer';

export interface MailMessage {
  to: string;
  subject: string;
  html: string;
  /** Plain-text version for mail apps that don't show HTML. */
  text: string;
}

/**
 * Sends email from noreply@minolingo.online through OVH's mail server (settings in backend/.env:
 * SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM).
 *
 * Without SMTP_PASS (a laptop without the mailbox password) nothing is sent: the message is
 * printed in the terminal instead, so you can still read the code or the link.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger('Mail');
  private readonly transport: Transporter | null;
  private readonly from: string;

  constructor(config: ConfigService) {
    const pass = config.get<string>('SMTP_PASS', '');
    const user = config.get<string>('SMTP_USER', 'noreply@minolingo.online');
    this.from = config.get<string>('MAIL_FROM', `MatchUp <${user}>`);
    this.transport = pass
      ? createTransport({
          host: config.get<string>('SMTP_HOST', 'ssl0.ovh.net'),
          port: Number(config.get('SMTP_PORT', 465)),
          secure: Number(config.get('SMTP_PORT', 465)) === 465,
          auth: { user, pass },
        })
      : null;
  }

  async send(message: MailMessage): Promise<void> {
    if (!this.transport) {
      this.logger.warn(`SMTP_PASS not set, email not sent. To ${message.to}: ${message.subject}\n${message.text}`);
      return;
    }
    await this.transport.sendMail({ from: this.from, ...message });
    this.logger.log(`Sent "${message.subject}" to ${message.to}`);
  }
}

/** Import once in a module (or rely on it being global) to inject [MailService]. */
@Global()
@Module({ providers: [MailService], exports: [MailService] })
export class MailModule {}
