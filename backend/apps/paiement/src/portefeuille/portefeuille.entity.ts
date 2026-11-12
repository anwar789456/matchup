import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, PrimaryColumn, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

/** Le solde MatchUp d’un utilisateur — table `paiement.portefeuille` (créé à la première utilisation). */
@Entity('portefeuille')
export class Portefeuille {
  /** id de l’utilisateur (module utilisateur). */
  @PrimaryColumn({ type: 'int' })
  utilisateurId: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  solde: number;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}

export const TYPES_MOUVEMENT = ['recharge', 'paiement', 'remboursement', 'ajustement'] as const;
export type TypeMouvement = (typeof TYPES_MOUVEMENT)[number];

/** Chaque mouvement du solde, avec le solde après — table `paiement.mouvement`. */
@Entity('mouvement')
export class Mouvement {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  utilisateurId: number;

  @Index()
  @Column({ type: 'varchar', length: 20 })
  type: TypeMouvement;

  /** Signé : +50 pour une recharge, −15 pour une part payée avec le solde. */
  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  montant: number;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal })
  soldeApres: number;

  @Column({ type: 'varchar', length: 255 })
  libelle: string;

  @Index()
  @Column({ type: 'int', nullable: true })
  paiementId?: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
