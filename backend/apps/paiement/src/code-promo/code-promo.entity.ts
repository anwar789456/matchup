import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/** Code promo du checkout (« BIENVENUE10 ») — table `paiement.code_promo`. */
@Entity('code_promo')
export class CodePromo {
  @PrimaryGeneratedColumn()
  id: number;

  /** Toujours en majuscules. */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 40 })
  code: string;

  /** −10 % … (ou un montant fixe). */
  @Column({ type: 'int', nullable: true })
  pourcentage?: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, nullable: true })
  montantFixe?: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, nullable: true })
  montantMin?: number | null;

  @Column({ type: 'timestamptz', nullable: true })
  debut?: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  fin?: Date | null;

  @Column({ type: 'int', nullable: true })
  utilisationsMax?: number | null;

  @Column({ type: 'int', default: 0 })
  utilisations: number;

  @Column({ type: 'boolean', default: true })
  actif: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
