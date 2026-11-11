import { decimal } from '@app/common';
import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

import { Tournoi } from '../tournoi/tournoi.entity';

/** en_attente (à valider par l’organisateur) → confirmee | refusee ; annulee par le capitaine. */
export const STATUTS_EQUIPE = ['en_attente', 'confirmee', 'refusee', 'annulee'] as const;
export const STATUTS_PAIEMENT = ['non_paye', 'paye', 'a_rembourser', 'rembourse', 'gratuit'] as const;
/** Statuts qui occupent une place dans le tournoi. */
export const EQUIPES_ACTIVES = ['en_attente', 'confirmee'];

/** Équipe inscrite à un tournoi (ou participant d’un événement) — table `tournois.equipe`. */
@Entity('equipe')
export class Equipe {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column({ type: 'int' })
  tournoiId: number;

  @ManyToOne(() => Tournoi, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'tournoiId' })
  tournoi?: Tournoi;

  @Column({ type: 'varchar', length: 255 })
  nom: string;

  @Column({ type: 'varchar', length: 500, nullable: true })
  logoUrl?: string | null;

  @Index()
  @Column({ type: 'int', nullable: true })
  capitaineId?: number | null;

  @Column({ type: 'int', array: true, default: () => "'{}'" })
  joueursIds: number[];

  @Index()
  @Column({ type: 'varchar', length: 20, default: 'en_attente' })
  statut: string;

  @Column({ type: 'varchar', length: 20, default: 'non_paye' })
  statutPaiement: string;

  /** id du paiement dans le module paiement. */
  @Column({ type: 'int', nullable: true })
  paiementId?: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 3, transformer: decimal, default: 0 })
  montantPaye: number;

  @Column({ type: 'text', nullable: true })
  motifRefus?: string | null;

  /** Code du lien d’invitation : les coéquipiers rejoignent l’équipe avec ce code. */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 12, nullable: true })
  codeInvitation?: string | null;

  /** Tête de série (1 = meilleure) ; null = ordre d’inscription. */
  @Column({ type: 'int', nullable: true })
  seed?: number | null;

  @Column({ type: 'timestamptz', nullable: true })
  valideeLe?: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
