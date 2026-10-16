import { createHash, randomBytes, randomInt } from 'crypto';

import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { MoreThan, Repository } from 'typeorm';

import { MailService } from '@app/common';
import { Utilisateur } from '../utilisateur/utilisateur.entity';
import { CodeEmail } from './code-email.entity';
import { resetCodeEmail, verificationEmail } from './emails';

const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

/**
 * Account emails: the sign-up confirmation link (AUTH-04) and the password reset code
 * (AUTH-06 → 07 → 08). Same rules as the app's screens: 3 wrong codes block for 10 minutes.
 */
@Injectable()
export class CompteService {
  private readonly logger = new Logger('Compte');

  static readonly linkValidity = 24 * 60 * 60 * 1000;
  static readonly codeValidity = 15 * 60 * 1000;
  static readonly maxAttempts = 3;
  static readonly blockDuration = 10 * 60 * 1000;

  constructor(
    @InjectRepository(CodeEmail) private readonly codes: Repository<CodeEmail>,
    @InjectRepository(Utilisateur) private readonly users: Repository<Utilisateur>,
    private readonly mail: MailService,
    private readonly config: ConfigService,
  ) {}

  private normalise(email: string) {
    return email.trim().toLowerCase();
  }

  /** Sends (again) the confirmation link. Silently does nothing for an unknown email. */
  async sendVerification(email: string): Promise<void> {
    const address = this.normalise(email);
    const user = await this.users.findOne({ where: { email: address } });
    if (!user || user.emailVerifie) return;
    const token = randomBytes(24).toString('hex');
    await this.codes.save(
      this.codes.create({
        email: address,
        usage: 'verification',
        hash: sha256(token),
        expireA: new Date(Date.now() + CompteService.linkValidity),
      }),
    );
    const base = this.config.get<string>('PUBLIC_URL', 'https://minolingo.online');
    const link = `${base}/api/utilisateur/compte/verification/confirmer?token=${token}`;
    await this.mail.send(verificationEmail(address, link));
  }

  /** Opens from the email: marks the address as confirmed. */
  async confirm(token: string): Promise<boolean> {
    const code = await this.codes.findOne({
      where: { hash: sha256(token ?? ''), usage: 'verification', utilise: false, expireA: MoreThan(new Date()) },
    });
    if (!code) return false;
    await this.users.update({ email: code.email }, { emailVerifie: true });
    await this.codes.update({ id: code.id }, { utilise: true });
    return true;
  }

  /** AUTH-06: always answers the same, so nobody can test which emails have an account. */
  async sendResetCode(email: string): Promise<void> {
    const address = this.normalise(email);
    const user = await this.users.findOne({ where: { email: address } });
    if (!user) {
      this.logger.log(`Reset asked for unknown ${address}`);
      return;
    }
    const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
    await this.codes.update({ email: address, usage: 'reinitialisation', utilise: false }, { utilise: true });
    await this.codes.save(
      this.codes.create({
        email: address,
        usage: 'reinitialisation',
        hash: sha256(code),
        expireA: new Date(Date.now() + CompteService.codeValidity),
      }),
    );
    await this.mail.send(resetCodeEmail(address, code));
  }

  /**
   * AUTH-07: checks the code without using it up. Wrong code → 400 with `essaisRestants`;
   * 3 wrong codes → 429 with `reessayerA`.
   */
  async checkResetCode(email: string, code: string): Promise<CodeEmail> {
    const address = this.normalise(email);
    const current = await this.codes.findOne({
      where: { email: address, usage: 'reinitialisation', utilise: false },
      order: { id: 'DESC' },
    });
    const now = new Date();
    if (current?.bloqueJusqua && current.bloqueJusqua > now) {
      throw this.blocked(current.bloqueJusqua);
    }
    if (!current || current.expireA <= now) {
      throw new BadRequestException({
        message: 'Ce code a expiré. Demande un nouveau code.',
        essaisRestants: 0,
      });
    }
    if (current.hash === sha256(code.trim())) return current;

    current.essais += 1;
    if (current.essais >= CompteService.maxAttempts) {
      current.bloqueJusqua = new Date(now.getTime() + CompteService.blockDuration);
      await this.codes.save(current);
      throw this.blocked(current.bloqueJusqua);
    }
    await this.codes.save(current);
    throw new BadRequestException({
      message: 'Code incorrect.',
      essaisRestants: CompteService.maxAttempts - current.essais,
    });
  }

  /** AUTH-08: new password, different from the old one; the code is then used up. */
  async resetPassword(email: string, code: string, motDePasse: string): Promise<void> {
    const current = await this.checkResetCode(email, code);
    const user = await this.users
      .createQueryBuilder('u')
      .addSelect('u.motDePasse')
      .where('u.email = :email', { email: current.email })
      .getOne();
    if (!user) throw new BadRequestException('Compte introuvable.');
    if (await bcrypt.compare(motDePasse, user.motDePasse)) {
      throw new ConflictException('Il doit être différent de l’ancien.');
    }
    await this.users.update({ id: user.id }, { motDePasse: await bcrypt.hash(motDePasse, 10) });
    await this.codes.update({ id: current.id }, { utilise: true });
  }

  private blocked(until: Date) {
    return new HttpException(
      { message: 'Trop d’essais. Réessaie dans 10 minutes.', reessayerA: until.toISOString() },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }
}
