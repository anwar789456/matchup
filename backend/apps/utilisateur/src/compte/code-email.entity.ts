import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/**
 * A code or link sent by email — table `utilisateur.code_email`.
 * `verification`: the sign-up confirmation link (AUTH-04); `reinitialisation`: the 6-digit
 * password reset code (AUTH-06/07). Only a hash is stored.
 */
@Entity('code_email')
export class CodeEmail {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'varchar', length: 255 })
  email: string;

  @Column({ type: 'varchar', length: 20 })
  usage: 'verification' | 'reinitialisation';

  /** sha256 of the code or token. */
  @Index()
  @Column({ type: 'varchar', length: 64 })
  hash: string;

  @Column({ type: 'timestamptz' })
  expireA: Date;

  @Column({ type: 'int', default: 0 })
  essais: number;

  /** After 3 wrong codes, no new try before this time. */
  @Column({ type: 'timestamptz', nullable: true })
  bloqueJusqua?: Date | null;

  @Column({ type: 'boolean', default: false })
  utilise: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
