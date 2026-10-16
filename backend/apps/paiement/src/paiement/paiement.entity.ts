import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Paiement — table `paiement.paiement`. */
@Entity('paiement')
export class Paiement {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Index()
  @Column({ type: 'int', nullable: true })
  reservationId?: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montant: number;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'carte' })
  methode: string;

  @Index()
  @Column({ type: 'varchar', length: 40, default: 'en_attente' })
  statut: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  reference?: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
